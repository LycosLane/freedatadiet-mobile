import 'dart:io';
import 'dart:isolate';
import '../models/duplicate_rule.dart';
import '../models/storage_item.dart';
import 'duplicate_finder_service.dart';

/// Request payload for scanning a directory in a background isolate.
class _ScanRequest {
  final List<String> rootPaths;
  final bool isRecursive;
  final bool showHidden;
  final List<String> excludedPatterns;
  final DuplicateMatchMode duplicateMode;
  final SendPort sendPort;

  const _ScanRequest({
    required this.rootPaths,
    required this.isRecursive,
    required this.showHidden,
    required this.excludedPatterns,
    required this.duplicateMode,
    required this.sendPort,
  });
}

/// Service providing non-blocking parallel directory traversal.
class StorageScannerService {
  StorageScannerService._();

  /// Scans either immediate directory children or all nested files recursively in a background isolate.
  static Future<List<StorageItem>> scanDirectory({
    required List<String> paths,
    required bool isRecursive,
    required bool showHidden,
    required List<String> excludedPatterns,
    required DuplicateMatchMode duplicateMode,
  }) async {
    final receivePort = ReceivePort();

    final request = _ScanRequest(
      rootPaths: paths,
      isRecursive: isRecursive,
      showHidden: showHidden,
      excludedPatterns: excludedPatterns,
      duplicateMode: duplicateMode,
      sendPort: receivePort.sendPort,
    );

    await Isolate.spawn(_isolateWorker, request);
    final List<StorageItem> rawItems = await receivePort.first as List<StorageItem>;
    receivePort.close();

    // If in recursive view, process duplicate matching
    if (isRecursive) {
      return DuplicateFinderService.markDuplicates(
        items: rawItems,
        mode: duplicateMode,
      );
    }

    return rawItems;
  }

  /// Worker function executed in the background isolate.
  static void _isolateWorker(_ScanRequest request) {
    final List<StorageItem> results = [];

    for (final rootPath in request.rootPaths) {
      final rootDir = Directory(rootPath);
      if (!rootDir.existsSync()) continue;

      if (request.isRecursive) {
        _collectAllNestedFiles(
          dir: rootDir,
          results: results,
          showHidden: request.showHidden,
          excludedPatterns: request.excludedPatterns,
        );
      } else {
        _collectImmediateChildren(
          dir: rootDir,
          results: results,
          showHidden: request.showHidden,
          excludedPatterns: request.excludedPatterns,
        );
      }
    }

    request.sendPort.send(results);
  }

  static void _collectImmediateChildren({
    required Directory dir,
    required List<StorageItem> results,
    required bool showHidden,
    required List<String> excludedPatterns,
  }) {
    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? entity.path;

        if (!showHidden && name.startsWith('.')) continue;
        if (_isExcluded(entity.path, excludedPatterns)) continue;

        if (entity is Directory) {
          final dirStats = _computeDirectoryStats(entity, excludedPatterns);
          results.add(StorageItem(
            path: entity.path,
            name: name,
            isDirectory: true,
            size: dirStats.totalSize,
            childCount: dirStats.itemCount,
            lastModified: _safeStatModified(entity),
            isSystem: name.startsWith('.') || name.toLowerCase() == 'android',
          ));
        } else if (entity is File) {
          final int length = _safeFileLength(entity);
          final ext = _extractExtension(name);
          results.add(StorageItem(
            path: entity.path,
            name: name,
            isDirectory: false,
            size: length,
            lastModified: _safeStatModified(entity),
            extension: ext,
          ));
        } else if (entity is Link) {
          results.add(StorageItem(
            path: entity.path,
            name: name,
            isDirectory: false,
            size: 0,
            isLink: true,
          ));
        }
      }
    } catch (_) {}
  }

  static void _collectAllNestedFiles({
    required Directory dir,
    required List<StorageItem> results,
    required bool showHidden,
    required List<String> excludedPatterns,
  }) {
    final List<Directory> stack = [dir];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      try {
        final entities = current.listSync(followLinks: false);
        for (final entity in entities) {
          final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? entity.path;

          if (!showHidden && name.startsWith('.')) continue;
          if (_isExcluded(entity.path, excludedPatterns)) continue;

          if (entity is Directory) {
            stack.add(entity);
          } else if (entity is File) {
            final length = _safeFileLength(entity);
            results.add(StorageItem(
              path: entity.path,
              name: name,
              isDirectory: false,
              size: length,
              lastModified: _safeStatModified(entity),
              extension: _extractExtension(name),
            ));
          }
        }
      } catch (_) {}
    }
  }

  static _DirStats _computeDirectoryStats(Directory dir, List<String> excludedPatterns) {
    int totalBytes = 0;
    int items = 0;
    try {
      final children = dir.listSync(recursive: false, followLinks: false);
      items = children.length;
      for (final child in children) {
        if (_isExcluded(child.path, excludedPatterns)) continue;
        if (child is File) {
          totalBytes += _safeFileLength(child);
        } else if (child is Directory) {
          // Approximate first-level directory size
          totalBytes += _shallowDirSize(child);
        }
      }
    } catch (_) {}
    return _DirStats(totalSize: totalBytes, itemCount: items);
  }

  static int _shallowDirSize(Directory dir) {
    int bytes = 0;
    try {
      final entries = dir.listSync(recursive: false, followLinks: false);
      for (final e in entries) {
        if (e is File) {
          bytes += _safeFileLength(e);
        }
      }
    } catch (_) {}
    return bytes;
  }

  static bool _isExcluded(String path, List<String> patterns) {
    for (final pattern in patterns) {
      if (path.contains(pattern)) return true;
    }
    return false;
  }

  static int _safeFileLength(File file) {
    try {
      return file.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  static DateTime? _safeStatModified(FileSystemEntity entity) {
    try {
      return entity.statSync().modified;
    } catch (_) {
      return null;
    }
  }

  static String _extractExtension(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < name.length - 1) {
      return name.substring(dotIndex).toLowerCase();
    }
    return '';
  }

  /// Permanently deletes a list of files or directories. Returns number of successfully deleted items.
  static Future<int> deleteItems(List<String> paths) async {
    int deletedCount = 0;
    for (final path in paths) {
      try {
        final type = FileSystemEntity.typeSync(path, followLinks: false);
        if (type == FileSystemEntityType.file || type == FileSystemEntityType.link) {
          File(path).deleteSync();
          deletedCount++;
        } else if (type == FileSystemEntityType.directory) {
          Directory(path).deleteSync(recursive: true);
          deletedCount++;
        }
      } catch (_) {}
    }
    return deletedCount;
  }
}

class _DirStats {
  final int totalSize;
  final int itemCount;
  const _DirStats({required this.totalSize, required this.itemCount});
}
