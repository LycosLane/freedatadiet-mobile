import '../models/storage_item.dart';
import '../models/user_settings.dart';

/// Represents a grouped entry in subfolder recursive view.
/// Can contain 1 occurrence (unique file) or multiple occurrences (same name, date, or duplicate).
class SubfolderEntry {
  final String key;
  final String
  commonValue; // The shared value shown in the header (e.g. file name or date)
  final List<StorageItem> occurrences;
  final bool isDuplicateCluster;

  const SubfolderEntry({
    required this.key,
    required this.commonValue,
    required this.occurrences,
    this.isDuplicateCluster = false,
  });

  bool get isMultiOccurrence => occurrences.length > 1;

  int get totalSize => occurrences.fold<int>(0, (sum, i) => sum + i.size);

  /// Representative item for badges and icons
  StorageItem get primaryItem => occurrences.first;
}

/// Pure business logic for grouping items in subfolder mode.
class SubfolderGrouper {
  SubfolderGrouper._();

  /// Groups [items] according to active [settings] (duplicates, name, date, size).
  static List<SubfolderEntry> group({
    required List<StorageItem> items,
    required UserSettings settings,
  }) {
    if (items.isEmpty) return const [];

    final Map<String, List<StorageItem>> map = {};
    final Map<String, String> commonValues = {};
    final Map<String, bool> isDupMap = {};

    for (final item in items) {
      final String groupKey;
      final String commonVal;
      bool isDup = false;

      if (settings.showDuplicatesOnly ||
          (item.isDuplicate && item.duplicateGroupId != null)) {
        groupKey = item.duplicateGroupId ?? 'name_${item.name.toLowerCase()}';
        commonVal = item.name;
        isDup = true;
      } else {
        switch (settings.sortColumn) {
          case SortColumn.name:
            groupKey = 'name_${item.name.toLowerCase()}';
            commonVal = item.name;
            break;
          case SortColumn.date:
            final d = item.lastModified;
            if (d != null) {
              groupKey =
                  'date_${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              commonVal =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            } else {
              groupKey = 'date_unknown';
              commonVal = 'Unknown date';
            }
            break;
          case SortColumn.size:
            groupKey = 'size_${item.size}';
            commonVal = item.name;
            break;
        }
      }

      map.putIfAbsent(groupKey, () => []).add(item);
      commonValues[groupKey] = commonVal;
      if (isDup) isDupMap[groupKey] = true;
    }

    final entries = map.entries.map((e) {
      return SubfolderEntry(
        key: e.key,
        commonValue: commonValues[e.key] ?? e.value.first.name,
        occurrences: e.value,
        isDuplicateCluster: isDupMap[e.key] ?? false,
      );
    }).toList();

    // Sort entries according to settings
    entries.sort((a, b) {
      // Duplicates or multi-occurrences with higher occurrence counts stay visible
      if (a.isMultiOccurrence != b.isMultiOccurrence) {
        return a.isMultiOccurrence ? -1 : 1;
      }

      final int cmp;
      switch (settings.sortColumn) {
        case SortColumn.name:
          cmp = a.commonValue.toLowerCase().compareTo(
            b.commonValue.toLowerCase(),
          );
          break;
        case SortColumn.date:
          final da =
              a.primaryItem.lastModified ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final db =
              b.primaryItem.lastModified ??
              DateTime.fromMillisecondsSinceEpoch(0);
          cmp = da.compareTo(db);
          break;
        case SortColumn.size:
          cmp = a.totalSize.compareTo(b.totalSize);
          break;
      }
      return settings.sortDescending ? -cmp : cmp;
    });

    return entries;
  }
}
