/// Represents storage statistics for an installed Android application.
/// Created instantly from the basic app list, then completed when its sizes arrive.
class AppStorageInfo {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final int appBytes; // APK / binary size
  final int dataBytes; // user data / databases (without cache)
  final int
  cacheBytes; // cache data (for example Spotify, YouTube, Telegram cache)

  /// True until the sizes of this app have been queried.
  final bool isCalculating;

  /// False if Android refused to give us detailed sizes for this app.
  final bool statsKnown;

  const AppStorageInfo({
    required this.packageName,
    required this.appName,
    required this.isSystemApp,
    this.appBytes = 0,
    this.dataBytes = 0,
    this.cacheBytes = 0,
    this.isCalculating = false,
    this.statsKnown = true,
  });

  int get totalBytes => appBytes + dataBytes + cacheBytes;

  /// From the fast first query: name and flags only, sizes still pending.
  factory AppStorageInfo.basicFromMap(Map<dynamic, dynamic> map) {
    return AppStorageInfo(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      isCalculating: true,
    );
  }

  /// Returns a copy completed with the sizes from a stats result.
  AppStorageInfo withStats(Map<dynamic, dynamic> map) {
    return AppStorageInfo(
      packageName: packageName,
      appName: appName,
      isSystemApp: isSystemApp,
      appBytes: (map['appBytes'] as num?)?.toInt() ?? 0,
      dataBytes: (map['dataBytes'] as num?)?.toInt() ?? 0,
      cacheBytes: (map['cacheBytes'] as num?)?.toInt() ?? 0,
      isCalculating: false,
      statsKnown: map['statsKnown'] as bool? ?? true,
    );
  }

  /// Marks the app as finished without detailed sizes (query failed).
  AppStorageInfo withoutStats() {
    return AppStorageInfo(
      packageName: packageName,
      appName: appName,
      isSystemApp: isSystemApp,
      isCalculating: false,
      statsKnown: false,
    );
  }
}
