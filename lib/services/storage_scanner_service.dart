import 'dart:io' show Directory, File, Link;

import '../core/utils/path_rules.dart';
import '../models/storage_item.dart';
import 'scan_fs.dart';

/// Result of listing one directory level.
class ShallowListing {
  final List<StorageItem> items;

  /// False if the directory itself is gone (for example the SD card was removed).
  final bool pathExists;

  /// True if the directory exists but could not be read completely.
  final bool hadErrors;

  const ShallowListing({
    required this.items,
    required this.pathExists,
    required this.hadErrors,
  });
}

/// Instant, single-level directory listing.
/// Folder sizes are calculated afterwards by [FolderSizeScan], so the list is visible immediately.
class StorageScannerService {
  StorageScannerService._();

  /// Lists one directory level. Sub-directories are flagged `isScanning: true`
  /// until their size arrives from the background scan.
  static ShallowListing listDirectory({
    required String path,
    required bool showHidden,
    required List<String> excludedPatterns,
  }) {
    final results = <StorageItem>[];
    var hadErrors = false;

    final dir = Directory(path);
    bool exists;
    try {
      exists = dir.existsSync();
    } catch (_) {
      exists = false;
    }
    if (!exists) {
      return const ShallowListing(
        items: [],
        pathExists: false,
        hadErrors: false,
      );
    }

    final matcher = ExclusionMatcher(excludedPatterns);
    try {
      for (final entity in dir.listSync(followLinks: false)) {
        final name = ScanFs.baseName(entity.path);

        if (!showHidden && name.startsWith('.')) continue;
        if (matcher.matches(entity.path)) continue;

        if (entity is Directory) {
          results.add(
            StorageItem(
              path: entity.path,
              name: name,
              isDirectory: true,
              size: 0,
              childCount: 0,
              lastModified: ScanFs.safeModified(entity),
              isSystem: name.toLowerCase() == 'android',
              isScanning: true,
            ),
          );
        } else if (entity is File) {
          results.add(
            StorageItem(
              path: entity.path,
              name: name,
              isDirectory: false,
              size: ScanFs.safeLength(entity),
              lastModified: ScanFs.safeModified(entity),
              extension: ScanFs.extensionOf(name),
            ),
          );
        } else if (entity is Link) {
          results.add(
            StorageItem(
              path: entity.path,
              name: name,
              isDirectory: false,
              size: 0,
              isLink: true,
            ),
          );
        }
      }
    } catch (_) {
      hadErrors = true;
    }

    return ShallowListing(
      items: results,
      pathExists: true,
      hadErrors: hadErrors,
    );
  }
}
