import 'dart:typed_data';

/// Represents storage statistics for an installed Android application.
class AppStorageInfo {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final int appBytes;   // APK / Binary size
  final int dataBytes;  // User data / Databases
  final int cacheBytes; // Cache data (e.g. Spotify, YouTube, Telegram cache)
  final int totalBytes;
  final Uint8List? iconBytes;

  const AppStorageInfo({
    required this.packageName,
    required this.appName,
    required this.isSystemApp,
    required this.appBytes,
    required this.dataBytes,
    required this.cacheBytes,
    required this.totalBytes,
    this.iconBytes,
  });

  factory AppStorageInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppStorageInfo(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      appBytes: (map['appBytes'] as num?)?.toInt() ?? 0,
      dataBytes: (map['dataBytes'] as num?)?.toInt() ?? 0,
      cacheBytes: (map['cacheBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      iconBytes: map['iconBytes'] as Uint8List?,
    );
  }
}
