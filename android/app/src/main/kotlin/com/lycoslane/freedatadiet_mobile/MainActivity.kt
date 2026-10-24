package com.lycoslane.freedatadiet_mobile

import android.app.AppOpsManager
import android.app.usage.StorageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Process
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.lycoslane.freedatadiet/native_bridge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                "getInstalledAppsUsage" -> {
                    Thread {
                        try {
                            val apps = queryAppsUsageStats()
                            runOnUiThread { result.success(apps) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("STATS_ERROR", e.localizedMessage, null) }
                        }
                    }.start()
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

    private fun queryAppsUsageStats(): List<Map<String, Any>> {
        val result = mutableListOf<Map<String, Any>>()
        val pm = packageManager
        val storageStatsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(Context.STORAGE_STATS_SERVICE) as? StorageStatsManager
        } else null

        val installedPackages = pm.getInstalledApplications(PackageManager.GET_META_DATA)

        for (appInfo in installedPackages) {
            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val appLabel = pm.getApplicationLabel(appInfo).toString()
            val packageName = appInfo.packageName

            var appBytes: Long = 0
            var dataBytes: Long = 0
            var cacheBytes: Long = 0

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && storageStatsManager != null) {
                try {
                    val uuid = if (appInfo.storageUuid != null) appInfo.storageUuid else StorageManager.UUID_DEFAULT
                    val stats = storageStatsManager.queryStatsForPackage(uuid, packageName, Process.myUserHandle())
                    appBytes = stats.appBytes
                    dataBytes = stats.dataBytes
                    cacheBytes = stats.cacheBytes
                } catch (_: Exception) {
                    // Fallback to checking apk size if stats permission wasn't granted or package inaccessible
                    val sourceFile = File(appInfo.sourceDir)
                    if (sourceFile.exists()) {
                        appBytes = sourceFile.length()
                    }
                }
            } else {
                val sourceFile = File(appInfo.sourceDir)
                if (sourceFile.exists()) {
                    appBytes = sourceFile.length()
                }
            }

            val totalBytes = appBytes + dataBytes + cacheBytes

            // Get icon thumbnail base64/bytes for visual polish
            val iconBytes = try {
                val drawable = pm.getApplicationIcon(appInfo)
                val bitmap = drawableToBitmap(drawable)
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 85, stream)
                stream.toByteArray()
            } catch (_: Exception) {
                null
            }

            val appMap = mutableMapOf<String, Any>(
                "packageName" to packageName,
                "appName" to appLabel,
                "isSystemApp" to isSystem,
                "appBytes" to appBytes,
                "dataBytes" to dataBytes,
                "cacheBytes" to cacheBytes,
                "totalBytes" to totalBytes
            )
            if (iconBytes != null) {
                appMap["iconBytes"] = iconBytes
            }

            result.add(appMap)
        }

        return result
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth.coerceAtMost(96) else 96
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight.coerceAtMost(96) else 96
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
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
