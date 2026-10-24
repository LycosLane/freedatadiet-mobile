import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_storage_info.dart';
import '../models/storage_volume.dart';

/// Bridges Flutter with native Android APIs via MethodChannel.
/// Provides safe fallbacks when running on Linux, macOS, or Windows.
class PlatformBridgeService {
  static const MethodChannel _channel = MethodChannel('com.lycoslane.freedatadiet/native_bridge');

  /// Checks if required permissions (All Files Access, Usage Stats) are granted.
  static Future<Map<String, bool>> checkPermissions() async {
    if (!Platform.isAndroid) {
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
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestStoragePermission');
      } catch (_) {}
    }
  }

  /// Requests Android Usage Stats access for App Diet calculations.
  static Future<void> requestUsageStatsPermission() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestUsageStatsPermission');
      } catch (_) {}
    }
  }

  /// Retrieves all accessible storage volumes (Internal flash, SD cards, USB OTG).
  static Future<List<StorageVolume>> getStorageVolumes() async {
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
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openAppStorageSettings', {
          'packageName': packageName,
        });
      } catch (_) {}
    }
  }
}
