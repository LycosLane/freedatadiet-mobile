import '../core/constants/app_constants.dart';

/// Represents a file or directory item in the disk tree.
class StorageItem {
  final String path;
  final String name;
  final bool isDirectory;
  final int size; // recursive size for directories, byte length for files
  final int childCount; // for directories: number of direct children
  final DateTime? lastModified;
  final String extension;
  final bool isSystem;
  final bool isLink;
  final bool isDuplicate;
  final String? duplicateGroupId;
  final bool isScanning; // true while folder size is being calculated in the background

  const StorageItem({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    this.childCount = 0,
    this.lastModified,
    this.extension = '',
    this.isSystem = false,
    this.isLink = false,
    this.isDuplicate = false,
    this.duplicateGroupId,
    this.isScanning = false,
  });

  String get badge {
    if (isSystem) return AppConstants.badgeSys;
    if (isLink) return AppConstants.badgeLink;
    if (isDirectory) return AppConstants.badgeDir;
    return AppConstants.badgeFile;
  }

  StorageItem copyWith({
    String? path,
    String? name,
    bool? isDirectory,
    int? size,
    int? childCount,
    DateTime? lastModified,
    String? extension,
    bool? isSystem,
    bool? isLink,
    bool? isDuplicate,
    String? duplicateGroupId,
    bool? isScanning,
    bool clearDuplicateGroup = false,
  }) {
    return StorageItem(
      path: path ?? this.path,
      name: name ?? this.name,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      childCount: childCount ?? this.childCount,
      lastModified: lastModified ?? this.lastModified,
      extension: extension ?? this.extension,
      isSystem: isSystem ?? this.isSystem,
      isLink: isLink ?? this.isLink,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      duplicateGroupId: clearDuplicateGroup ? null : (duplicateGroupId ?? this.duplicateGroupId),
      isScanning: isScanning ?? this.isScanning,
    );
  }
}
