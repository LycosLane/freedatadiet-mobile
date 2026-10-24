import '../models/storage_item.dart';

/// Suggestion produced by the duplicate assistant when a user selects a duplicate copy.
class DuplicateAssistantSuggestion {
  final String directoryPath;
  final String directoryName;
  final List<String> candidatePaths;

  const DuplicateAssistantSuggestion({
    required this.directoryPath,
    required this.directoryName,
    required this.candidatePaths,
  });

  int get count => candidatePaths.length;
}

/// Helper service that analyzes duplicate selections and identifies sibling duplicates
/// residing in the same folder that could also be selected for deletion.
class DuplicateAssistantService {
  DuplicateAssistantService._();

  static String getDirectory(String fullPath) {
    final slash = fullPath.lastIndexOf('/');
    if (slash == -1) return '';
    return fullPath.substring(0, slash);
  }

  static String getBasename(String path) {
    final slash = path.lastIndexOf('/');
    if (slash == -1 || slash == path.length - 1) return path;
    return path.substring(slash + 1);
  }

  /// Analyzes currently selected items and finds other unselected duplicates
  /// located in the same directory as selected duplicates.
  static DuplicateAssistantSuggestion? findSuggestion({
    required List<StorageItem> allItems,
    required Set<String> selectedPaths,
  }) {
    if (selectedPaths.isEmpty) return null;

    final Map<String, List<StorageItem>> duplicateGroups = {};
    for (final item in allItems) {
      if (item.isDuplicate && item.duplicateGroupId != null) {
        duplicateGroups.putIfAbsent(item.duplicateGroupId!, () => []).add(item);
      }
    }

    // Find directories of selected duplicate items
    final Set<String> selectedDuplicateDirs = {};
    for (final item in allItems) {
      if (selectedPaths.contains(item.path) && item.isDuplicate) {
        final dir = getDirectory(item.path);
        if (dir.isNotEmpty) {
          selectedDuplicateDirs.add(dir);
        }
      }
    }

    if (selectedDuplicateDirs.isEmpty) return null;

    // Check for candidate unselected duplicates in these directories
    for (final dir in selectedDuplicateDirs) {
      final candidates = <String>[];

      for (final group in duplicateGroups.values) {
        // If this group has an occurrence in dir that is NOT yet selected
        final inDirUnselected = group
            .where(
              (i) =>
                  getDirectory(i.path) == dir &&
                  !selectedPaths.contains(i.path),
            )
            .toList();

        // And has another occurrence outside dir that is NOT selected (the keeper/original)
        final outsideDirKept = group
            .where(
              (i) =>
                  getDirectory(i.path) != dir &&
                  !selectedPaths.contains(i.path),
            )
            .toList();

        if (inDirUnselected.isNotEmpty && outsideDirKept.isNotEmpty) {
          for (final item in inDirUnselected) {
            candidates.add(item.path);
          }
        }
      }

      if (candidates.isNotEmpty) {
        return DuplicateAssistantSuggestion(
          directoryPath: dir,
          directoryName: getBasename(dir),
          candidatePaths: candidates,
        );
      }
    }

    return null;
  }
}
