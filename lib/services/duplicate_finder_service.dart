import '../models/duplicate_rule.dart';
import '../models/storage_item.dart';

/// Analyzes storage items and tags duplicates based on enabled criteria checkboxes.
class DuplicateFinderService {
  DuplicateFinderService._();

  /// Scans items and returns a list with items updated with duplicate flags and group IDs.
  static List<StorageItem> markDuplicates({
    required List<StorageItem> items,
    required DuplicateMatchCriteria criteria,
  }) {
    if (!criteria.isEnabled) {
      return items
          .map((i) => i.copyWith(isDuplicate: false, clearDuplicateGroup: true))
          .toList();
    }

    // Only compare files, not directories
    final fileItems = items.where((item) => !item.isDirectory).toList();
    if (fileItems.length < 2) return items;

    final Map<String, List<StorageItem>> clusters = {};

    for (final item in fileItems) {
      final key = _buildKey(item, criteria);
      if (key == null) continue;
      clusters.putIfAbsent(key, () => []).add(item);
    }

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

    return items.map((item) {
      final groupId = duplicatePathToGroupId[item.path];
      if (groupId != null) {
        return item.copyWith(isDuplicate: true, duplicateGroupId: groupId);
      }
      return item.copyWith(isDuplicate: false, clearDuplicateGroup: true);
    }).toList();
  }

  static String? _buildKey(StorageItem item, DuplicateMatchCriteria criteria) {
    if (item.size <= 0 && criteria.matchSize) return null;

    final parts = <String>[];

    if (criteria.matchName) {
      parts.add('NAME:${item.name.toLowerCase()}');
    }
    if (criteria.matchSize) {
      parts.add('SIZE:${item.size}');
    }
    if (criteria.matchTimestamp) {
      final ms = item.lastModified?.millisecondsSinceEpoch ?? 0;
      if (ms > 0) {
        parts.add('TIME:$ms');
      } else {
        return null;
      }
    }

    return parts.isEmpty ? null : parts.join('|');
  }
}
