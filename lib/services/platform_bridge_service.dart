import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_storage_info.dart';
import '../models/storage_volume.dart';

/// Bridges Flutter with native Android APIs via MethodChannel / EventChannel.
/// Provides safe fallbacks when running on Linux or other non-Android platforms.
class PlatformBridgeService {
  static const String _channelBase = 'com.lycoslane.freedatadiet_mobile';
  static const MethodChannel _channel = MethodChannel(
    '$_channelBase/native_bridge',
  );
  static const EventChannel _volumeEvents = EventChannel(
    '$_channelBase/volume_events',
  );

  /// Fires whenever a storage volume is mounted, unmounted or removed.
  /// Listeners should re-read [getStorageVolumes] to see what changed.
  static Stream<void> get volumeChanges {
    if (!Platform.isAndroid) return const Stream<void>.empty();
    return _volumeEvents
        .receiveBroadcastStream()
        .map((_) {})
        .handleError((_) {});
  }

  /// Checks if required permissions (All Files Access, Usage Stats) are granted.
  static Future<Map<String, bool>> checkPermissions() async {
    if (!Platform.isAndroid) {
      return {'hasStoragePermission': true, 'hasUsageStatsPermission': true};
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'checkPermissions',
      );
      return {
        'hasStoragePermission':
            result?['hasStoragePermission'] as bool? ?? false,
        'hasUsageStatsPermission':
            result?['hasUsageStatsPermission'] as bool? ?? false,
      };
    } catch (_) {
      return {'hasStoragePermission': false, 'hasUsageStatsPermission': false};
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

  /// Retrieves all accessible storage volumes (internal flash, SD cards, USB OTG).
  static Future<List<StorageVolume>> getStorageVolumes() async {
    if (Platform.isAndroid) {
      try {
        final List<dynamic>? rawVolumes = await _channel.invokeListMethod(
          'getStorageVolumes',
        );
        if (rawVolumes != null && rawVolumes.isNotEmpty) {
          return rawVolumes
              .map((map) => StorageVolume.fromMap(map as Map<dynamic, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    // Fallback detection for Linux / desktop or if the channel returns nothing
    final List<StorageVolume> fallbackList = [];
    try {
      final docDir = await getApplicationDocumentsDirectory();

      fallbackList.add(
        StorageVolume(
          path: Platform.isAndroid ? '/storage/emulated/0' : docDir.path,
          description: 'Internal Storage',
          isPrimary: true,
          isRemovable: false,
          totalBytes: 0,
          freeBytes: 0,
          usableBytes: 0,
        ),
      );
    } catch (_) {}

    return fallbackList;
  }

  /// Fast first query: every installed app with name and flags, but no sizes yet.
  static Future<List<AppStorageInfo>> getInstalledAppsBasic() async {
    if (!Platform.isAndroid) return [];
    try {
      final List<dynamic>? raw = await _channel.invokeListMethod(
        'getInstalledAppsBasic',
      );
      if (raw != null) {
        return raw
            .map((m) => AppStorageInfo.basicFromMap(m as Map<dynamic, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Queries sizes for a batch of packages. Returns a map package name to stats map.
  static Future<Map<String, Map<dynamic, dynamic>>> getAppStats(
    List<String> packageNames,
  ) async {
    if (!Platform.isAndroid || packageNames.isEmpty) return {};
    try {
      final List<dynamic>? raw = await _channel.invokeListMethod(
        'getAppStats',
        {'packageNames': packageNames},
      );
      if (raw != null) {
        return {
          for (final entry in raw)
            (entry as Map<dynamic, dynamic>)['packageName'] as String: entry,
        };
      }
    } catch (_) {}
    return {};
  }

  /// Loads one small app icon (PNG bytes), or null if none is available.
  static Future<Uint8List?> getAppIcon(String packageName) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('getAppIcon', {
        'packageName': packageName,
      });
    } catch (_) {
      return null;
    }
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

  /// Opens a file with the system default viewer/handler via Android Intent.
  static Future<void> openFile(String filePath) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('openFile', {'filePath': filePath});
  }
}
