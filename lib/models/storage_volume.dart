/// Represents a detected storage volume (Internal flash, SD card, OTG).
class StorageVolume {
  final String path;
  final String description;
  final bool isPrimary;
  final bool isRemovable;
  final int totalBytes;
  final int freeBytes;
  final int usableBytes;

  const StorageVolume({
    required this.path,
    required this.description,
    required this.isPrimary,
    required this.isRemovable,
    required this.totalBytes,
    required this.freeBytes,
    required this.usableBytes,
  });

  int get usedBytes => (totalBytes - freeBytes).clamp(0, totalBytes);

  double get usedRatio {
    if (totalBytes <= 0) return 0.0;
    return (usedBytes / totalBytes).clamp(0.0, 1.0);
  }

  factory StorageVolume.fromMap(Map<dynamic, dynamic> map) {
    return StorageVolume(
      path: map['path'] as String? ?? '',
      description: map['description'] as String? ?? 'Storage',
      isPrimary: map['isPrimary'] as bool? ?? false,
      isRemovable: map['isRemovable'] as bool? ?? false,
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      freeBytes: (map['freeBytes'] as num?)?.toInt() ?? 0,
      usableBytes: (map['usableBytes'] as num?)?.toInt() ?? 0,
    );
  }
}
