import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_storage_info.dart';
import '../models/storage_volume.dart';

/// Bridges Flutter with native Android APIs via MethodChannel.
/// Provides safe fallbacks when running on Linux, macOS, Windows, or Web preview.
class PlatformBridgeService {
  static const MethodChannel _channel = MethodChannel('com.lycoslane.freedatadiet/native_bridge');

  /// Checks if required permissions (All Files Access, Usage Stats) are granted.
  static Future<Map<String, bool>> checkPermissions() async {
    if (kIsWeb || !Platform.isAndroid) {
      return {
        'hasStoragePermission': true,
        'hasUsageStatsPermission': true,
      };
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkPermissions');
      return {
        'hasStoragePermission': result?['hasStoragePermission'] as bool? ?? false,
        'hasUsageStatsPermission': result?['hasUsageStatsPermission'] as bool? ?? false,
      };
    } catch (_) {
      return {
        'hasStoragePermission': false,
        'hasUsageStatsPermission': false,
      };
    }
  }

  /// Requests Android "All Files Access" (MANAGE_EXTERNAL_STORAGE).
  static Future<void> requestStoragePermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestStoragePermission');
      } catch (_) {}
    }
  }

  /// Requests Android Usage Stats access for App Diet calculations.
  static Future<void> requestUsageStatsPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestUsageStatsPermission');
      } catch (_) {}
    }
  }

  /// Retrieves all accessible storage volumes (Internal flash, SD cards, USB OTG).
  static Future<List<StorageVolume>> getStorageVolumes() async {
    if (kIsWeb) {
      return const [
        StorageVolume(
          path: '/storage/emulated/0',
          description: 'Internal Storage',
          isPrimary: true,
          isRemovable: false,
          totalBytes: 128 * 1024 * 1024 * 1024,
          freeBytes: 42 * 1024 * 1024 * 1024,
          usableBytes: 42 * 1024 * 1024 * 1024,
        ),
        StorageVolume(
          path: '/storage/1A2B-3C4D',
          description: 'Samsung 256GB MicroSD',
          isPrimary: false,
          isRemovable: true,
          totalBytes: 256 * 1024 * 1024 * 1024,
          freeBytes: 135 * 1024 * 1024 * 1024,
          usableBytes: 135 * 1024 * 1024 * 1024,
        ),
      ];
    }

    if (Platform.isAndroid) {
      try {
        final List<dynamic>? rawVolumes = await _channel.invokeListMethod('getStorageVolumes');
        if (rawVolumes != null && rawVolumes.isNotEmpty) {
          return rawVolumes
              .map((map) => StorageVolume.fromMap(map as Map<dynamic, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    // Fallback detection for Linux / desktop or if channel returns empty
    final List<StorageVolume> fallbackList = [];
    try {
      final docDir = await getApplicationDocumentsDirectory();

      fallbackList.add(StorageVolume(
        path: Platform.isAndroid ? '/storage/emulated/0' : docDir.path,
        description: 'Internal Storage',
        isPrimary: true,
        isRemovable: false,
        totalBytes: 64 * 1024 * 1024 * 1024,
        freeBytes: 20 * 1024 * 1024 * 1024,
        usableBytes: 20 * 1024 * 1024 * 1024,
      ));
    } catch (_) {}

    return fallbackList;
  }

  /// Queries all installed apps and their storage stats (APK, Data, Cache).
  static Future<List<AppStorageInfo>> getInstalledAppsUsage() async {
    if (kIsWeb) {
      return const [
        AppStorageInfo(
          packageName: 'com.spotify.music',
          appName: 'Spotify',
          isSystemApp: false,
          appBytes: 115 * 1024 * 1024,
          dataBytes: 2 * 1024 * 1024 * 1024,
          cacheBytes: 18 * 1024 * 1024 * 1024 + 400 * 1024 * 1024, // 18.4 GB Cache
          totalBytes: 20 * 1024 * 1024 * 1024 + 515 * 1024 * 1024,
        ),
        AppStorageInfo(
          packageName: 'org.telegram.messenger',
          appName: 'Telegram',
          isSystemApp: false,
          appBytes: 175 * 1024 * 1024,
          dataBytes: 1 * 1024 * 1024 * 1024,
          cacheBytes: 12 * 1024 * 1024 * 1024 + 200 * 1024 * 1024, // 12.2 GB Cache
          totalBytes: 13 * 1024 * 1024 * 1024 + 375 * 1024 * 1024,
        ),
        AppStorageInfo(
          packageName: 'com.google.android.youtube',
          appName: 'YouTube',
          isSystemApp: false,
          appBytes: 220 * 1024 * 1024,
          dataBytes: 800 * 1024 * 1024,
          cacheBytes: 7 * 1024 * 1024 * 1024 + 500 * 1024 * 1024, // 7.5 GB Cache
          totalBytes: 8 * 1024 * 1024 * 1024 + 520 * 1024 * 1024,
        ),
        AppStorageInfo(
          packageName: 'com.zhiliaoapp.musically',
          appName: 'TikTok',
          isSystemApp: false,
          appBytes: 240 * 1024 * 1024,
          dataBytes: 450 * 1024 * 1024,
          cacheBytes: 6 * 1024 * 1024 * 1024 + 100 * 1024 * 1024,
          totalBytes: 6 * 1024 * 1024 * 1024 + 790 * 1024 * 1024,
        ),
        AppStorageInfo(
          packageName: 'com.whatsapp',
          appName: 'WhatsApp',
          isSystemApp: false,
          appBytes: 140 * 1024 * 1024,
          dataBytes: 5 * 1024 * 1024 * 1024,
          cacheBytes: 850 * 1024 * 1024,
          totalBytes: 5 * 1024 * 1024 * 1024 + 990 * 1024 * 1024,
        ),
        AppStorageInfo(
          packageName: 'com.sec.android.app.camera',
          appName: 'Samsung Gallery & Camera',
          isSystemApp: true,
          appBytes: 90 * 1024 * 1024,
          dataBytes: 320 * 1024 * 1024,
          cacheBytes: 2 * 1024 * 1024 * 1024 + 800 * 1024 * 1024,
          totalBytes: 3 * 1024 * 1024 * 1024 + 210 * 1024 * 1024,
        ),
      ];
    }

    if (!Platform.isAndroid) return [];

    try {
      final List<dynamic>? rawApps = await _channel.invokeListMethod('getInstalledAppsUsage');
      if (rawApps != null) {
        return rawApps
            .map((map) => AppStorageInfo.fromMap(map as Map<dynamic, dynamic>))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  /// Opens the native system App Info / Storage details page for an app.
  static Future<void> openAppStorageSettings(String packageName) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openAppStorageSettings', {
          'packageName': packageName,
        });
      } catch (_) {}
    }
  }
}
