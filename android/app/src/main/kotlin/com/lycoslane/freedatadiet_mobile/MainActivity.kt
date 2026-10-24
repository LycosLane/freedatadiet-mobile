package com.lycoslane.freedatadiet_mobile

import android.app.AppOpsManager
import android.app.usage.StorageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Process
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.lycoslane.freedatadiet_mobile/native_bridge"
    private val VOLUME_CHANNEL = "com.lycoslane.freedatadiet_mobile/volume_events"

    private val worker: ExecutorService = Executors.newFixedThreadPool(2)
    private var volumeSink: EventChannel.EventSink? = null
    private var volumeReceiver: BroadcastReceiver? = null
    private var volumeCallback: Any? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    volumeSink = events
                    registerVolumeListeners()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterVolumeListeners()
                    volumeSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    val permissions = checkAppPermissions()
                    result.success(permissions)
                }
                "requestStoragePermission" -> {
                    requestStorageAccess()
                    result.success(true)
                }
                "requestUsageStatsPermission" -> {
                    requestUsageStatsAccess()
                    result.success(true)
                }
                "getStorageVolumes" -> {
                    val volumes = getAvailableStorageVolumes()
                    result.success(volumes)
                }
                "getInstalledAppsBasic" -> {
                    worker.execute {
                        try {
                            val apps = queryBasicApps()
                            runOnUiThread { result.success(apps) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("APPS_ERROR", e.localizedMessage, null) }
                        }
                    }
                }
                "getAppStats" -> {
                    val packageNames = call.argument<List<String>>("packageNames")
                    if (packageNames == null) {
                        result.error("INVALID_ARG", "packageNames is required", null)
                    } else {
                        worker.execute {
                            try {
                                val stats = packageNames.map { queryAppStats(it) }
                                runOnUiThread { result.success(stats) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("STATS_ERROR", e.localizedMessage, null) }
                            }
                        }
                    }
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) {
                        result.error("INVALID_ARG", "packageName is required", null)
                    } else {
                        worker.execute {
                            val bytes = queryAppIcon(packageName)
                            runOnUiThread { result.success(bytes) }
                        }
                    }
                }
                "openAppStorageSettings" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        openApplicationStorageDetails(packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARG", "Package name is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkAppPermissions(): Map<String, Boolean> {
        val storageGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            context.checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }

        val usageGranted = isUsageStatsGranted()

        return mapOf(
            "hasStoragePermission" to storageGranted,
            "hasUsageStatsPermission" to usageGranted
        )
    }

    private fun isUsageStatsGranted(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            } else {
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) {
            false
        }
    }

    private fun requestStorageAccess() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            } catch (_: Exception) {
                val fallbackIntent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(fallbackIntent)
            }
        } else {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    private fun requestUsageStatsAccess() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (_: Exception) {
            val fallbackIntent = Intent(Settings.ACTION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(fallbackIntent)
        }
    }

    private fun getAvailableStorageVolumes(): List<Map<String, Any>> {
        val volumeList = mutableListOf<Map<String, Any>>()
        val storageManager = getSystemService(Context.STORAGE_SERVICE) as? StorageManager ?: return volumeList

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val volumes = storageManager.storageVolumes
            for (volume in volumes) {
                val path = getVolumeDirectory(volume) ?: continue
                val file = File(path)
                if (!file.exists() || !file.canRead()) continue

                val isPrimary = volume.isPrimary
                val isRemovable = volume.isRemovable
                val description = volume.getDescription(this) ?: if (isPrimary) "Internal Storage" else "External Storage"

                volumeList.add(mapOf(
                    "path" to path,
                    "description" to description,
                    "isPrimary" to isPrimary,
                    "isRemovable" to isRemovable,
                    "totalBytes" to file.totalSpace,
                    "freeBytes" to file.freeSpace,
                    "usableBytes" to file.usableSpace
                ))
            }
        }

        // Fallback for primary storage if list is empty
        if (volumeList.isEmpty()) {
            val primaryFile = Environment.getExternalStorageDirectory()
            if (primaryFile != null && primaryFile.exists()) {
                volumeList.add(mapOf(
                    "path" to primaryFile.absolutePath,
                    "description" to "Internal Storage",
                    "isPrimary" to true,
                    "isRemovable" to false,
                    "totalBytes" to primaryFile.totalSpace,
                    "freeBytes" to primaryFile.freeSpace,
                    "usableBytes" to primaryFile.usableSpace
                ))
            }
        }

        return volumeList
    }

    private fun getVolumeDirectory(volume: StorageVolume): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            volume.directory?.absolutePath
        } else {
            try {
                val getPathMethod = volume.javaClass.getMethod("getPath")
                getPathMethod.invoke(volume) as? String
            } catch (_: Exception) {
                null
            }
        }
    }

    /// Fast query: every installed app with name and system flag. No sizes, no icons.
    private fun queryBasicApps(): List<Map<String, Any>> {
        val pm = packageManager
        return pm.getInstalledApplications(0).map { appInfo ->
            mapOf(
                "packageName" to appInfo.packageName,
                "appName" to pm.getApplicationLabel(appInfo).toString(),
                "isSystemApp" to ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0)
            )
        }
    }

    /// Sizes for one package. dataBytes from Android already contains the cache, so it is split here.
    private fun queryAppStats(pkg: String): Map<String, Any> {
        val pm = packageManager
        val appInfo = try {
            pm.getApplicationInfo(pkg, 0)
        } catch (_: Exception) {
            return mapOf("packageName" to pkg, "statsKnown" to false, "appBytes" to 0L, "dataBytes" to 0L, "cacheBytes" to 0L)
        }

        var appBytes = 0L
        var dataBytes = 0L
        var cacheBytes = 0L
        var known = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val statsManager = getSystemService(Context.STORAGE_STATS_SERVICE) as StorageStatsManager
                // Apps on adoptable external storage live on another volume UUID.
                val uuid = appInfo.storageUuid ?: StorageManager.UUID_DEFAULT
                val stats = statsManager.queryStatsForPackage(uuid, pkg, Process.myUserHandle())
                appBytes = stats.appBytes
                cacheBytes = stats.cacheBytes
                dataBytes = (stats.dataBytes - stats.cacheBytes).coerceAtLeast(0)
                known = true
            } catch (_: Exception) {
                // Usage access missing, volume not mounted or package not accessible.
            }
        }

        if (!known) {
            // Honest fallback: only the APK size is known. Dart shows data and cache as unavailable.
            val source = File(appInfo.sourceDir)
            if (source.exists()) appBytes = source.length()
        }

        return mapOf(
            "packageName" to pkg,
            "statsKnown" to known,
            "appBytes" to appBytes,
            "dataBytes" to dataBytes,
            "cacheBytes" to cacheBytes
        )
    }

    /// Small PNG icon, loaded on demand per visible row.
    private fun queryAppIcon(pkg: String): ByteArray? {
        return try {
            val drawable = packageManager.getApplicationIcon(pkg)
            val size = 96
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
            bitmap.recycle()
            stream.toByteArray()
        } catch (_: Exception) {
            null
        }
    }

    // ---------------------------------------------------------------------------------------
    // Storage volume change notifications (SD card or USB OTG mounted / removed)
    // ---------------------------------------------------------------------------------------

    private fun notifyVolumeChange() {
        runOnUiThread { volumeSink?.success("changed") }
    }

    private fun registerVolumeListeners() {
        if (volumeReceiver == null) {
            val receiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    notifyVolumeChange()
                }
            }
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_MEDIA_MOUNTED)
                addAction(Intent.ACTION_MEDIA_UNMOUNTED)
                addAction(Intent.ACTION_MEDIA_EJECT)
                addAction(Intent.ACTION_MEDIA_REMOVED)
                addAction(Intent.ACTION_MEDIA_BAD_REMOVAL)
                addDataScheme("file")
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                registerReceiver(receiver, filter)
            }
            volumeReceiver = receiver
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && volumeCallback == null) {
            val storageManager = getSystemService(Context.STORAGE_SERVICE) as? StorageManager
            val callback = object : StorageManager.StorageVolumeCallback() {
                override fun onStateChanged(volume: StorageVolume) {
                    notifyVolumeChange()
                }
            }
            storageManager?.registerStorageVolumeCallback(mainExecutor, callback)
            volumeCallback = callback
        }
    }

    private fun unregisterVolumeListeners() {
        volumeReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {
            }
        }
        volumeReceiver = null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            (volumeCallback as? StorageManager.StorageVolumeCallback)?.let {
                (getSystemService(Context.STORAGE_SERVICE) as? StorageManager)?.unregisterStorageVolumeCallback(it)
            }
        }
        volumeCallback = null
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        unregisterVolumeListeners()
        volumeSink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }
    private fun openApplicationStorageDetails(pkgName: String) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$pkgName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (_: Exception) {
            val fallback = Intent(Settings.ACTION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(fallback)
        }
    }
}
