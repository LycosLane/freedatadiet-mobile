import '../models/storage_item.dart';
import '../models/user_settings.dart';

/// Pure filtering and sorting of the file table (search text, "What's Shown" switches, duplicates, sort column).
/// Kept separate from the widget so it can be tested without any UI.
class ItemViewFilter {
  ItemViewFilter._();

  // File type groups behind the "What's Shown" switches
  static const Set<String> imageExts = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.dng',
    '.raw',
    '.gif',
    '.bmp',
    '.svg',
  };
  static const Set<String> videoExts = {
    '.mp4',
    '.mkv',
    '.mov',
    '.avi',
    '.webm',
    '.3gp',
    '.ts',
    '.m4v',
  };
  static const Set<String> audioExts = {
    '.mp3',
    '.flac',
    '.m4a',
    '.wav',
    '.ogg',
    '.opus',
    '.aac',
    '.wma',
  };
  static const Set<String> documentExts = {
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
    '.epub',
    '.xlsx',
    '.xls',
    '.pptx',
    '.ppt',
    '.csv',
    '.md',
  };
  static const Set<String> archiveExts = {
    '.zip',
    '.rar',
    '.7z',
    '.tar',
    '.gz',
    '.apk',
    '.obb',
    '.bz2',
    '.xz',
  };

  /// Returns true if the file path has an image extension.
  static bool isImage(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return false;
    return imageExts.contains(path.substring(dot).toLowerCase());
  }

  /// Returns the items that should be visible, sorted according to [settings].
  /// [searchQuery] (from the app bar) wins over the saved filter text.
  static List<StorageItem> apply({
    required List<StorageItem> items,
    required UserSettings settings,
    String searchQuery = '',
  }) {
    final s = settings;
    final combinedSearch =
        (searchQuery.isNotEmpty ? searchQuery : s.customFilterText.trim())
            .toLowerCase();

    final list = items.where((item) {
      if (combinedSearch.isNotEmpty) {
        final matchesName = item.name.toLowerCase().contains(combinedSearch);
        final matchesExt = item.extension.contains(combinedSearch);
        if (!matchesName && !matchesExt) return false;
      }

      if (!s.showHiddenFiles && item.name.startsWith('.')) return false;

      if (s.showDuplicatesOnly && (item.isDirectory || !item.isDuplicate)) {
        return false;
      }

      if (!item.isDirectory) {
        final ext = item.extension;
        if (!s.showImages && imageExts.contains(ext)) return false;
        if (!s.showVideos && videoExts.contains(ext)) return false;
        if (!s.showAudio && audioExts.contains(ext)) return false;
        if (!s.showDocuments && documentExts.contains(ext)) return false;
        if (!s.showArchives && archiveExts.contains(ext)) return false;
      }
      return true;
    }).toList();

    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    list.sort((a, b) {
      // When sorting by size descending: folders still scanning appear on top
      if (s.sortColumn == SortColumn.size && s.sortDescending) {
        if (a.isScanning && !b.isScanning) return -1;
        if (!a.isScanning && b.isScanning) return 1;
      }

      if (!s.includeSubfolders) {
        // In hierarchy mode, keep directories grouped on top
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
      }

      final int cmp;
      switch (s.sortColumn) {
        case SortColumn.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortColumn.date:
          cmp = (a.lastModified ?? epoch).compareTo(b.lastModified ?? epoch);
          break;
        case SortColumn.size:
          cmp = a.size.compareTo(b.size);
          break;
      }
      return s.sortDescending ? -cmp : cmp;
    });

    return list;
  }
}
