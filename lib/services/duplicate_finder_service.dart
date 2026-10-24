import '../models/duplicate_rule.dart';
import '../models/storage_item.dart';

/// Analyzes a list of storage items and tags duplicates based on criteria.
class DuplicateFinderService {
  DuplicateFinderService._();

  /// Scans items and returns a map with items updated with duplicate tags.
  static List<StorageItem> markDuplicates({
    required List<StorageItem> items,
    required DuplicateMatchMode mode,
  }) {
    // Only compare files, not directories
    final fileItems = items.where((item) => !item.isDirectory).toList();
    if (fileItems.length < 2) return items;

    // Build clusters according to criteria
    final Map<String, List<StorageItem>> clusters = {};

    for (final item in fileItems) {
      final key = _generateKey(item, mode);
      if (key == null) continue;
      clusters.putIfAbsent(key, () => []).add(item);
    }

    // Keep only clusters with 2 or more files
    final Map<String, String> duplicatePathToGroupId = {};
    int groupIndex = 1;

    for (final entry in clusters.entries) {
      if (entry.value.length >= 2) {
        final groupId = 'dup_$groupIndex';
        groupIndex++;
        for (final item in entry.value) {
          duplicatePathToGroupId[item.path] = groupId;
        }
      }
    }

    // Update original items with duplicate flags
    return items.map((item) {
      final groupId = duplicatePathToGroupId[item.path];
      if (groupId != null) {
        return item.copyWith(
          isDuplicate: true,
          duplicateGroupId: groupId,
        );
      }
      return item.copyWith(
        isDuplicate: false,
        duplicateGroupId: null,
      );
    }).toList();
  }

  static String? _generateKey(StorageItem item, DuplicateMatchMode mode) {
    // Ignore 0-byte empty files from duplicate groupings
    if (item.size <= 0) return null;

    final nameLower = item.name.toLowerCase();
    final size = item.size;
    final timeMs = item.lastModified?.millisecondsSinceEpoch ?? 0;

    switch (mode) {
      case DuplicateMatchMode.nameAndSize:
        return 'NAME_SIZE:${nameLower}_$size';
      case DuplicateMatchMode.sizeOnly:
        return 'SIZE:$size';
      case DuplicateMatchMode.nameOnly:
        return 'NAME:$nameLower';
      case DuplicateMatchMode.timestampOnly:
        return timeMs > 0 ? 'TIME:$timeMs' : null;
      case DuplicateMatchMode.nameSizeAndTimestamp:
        return 'FULL:${nameLower}_${size}_$timeMs';
    }
  }
}
