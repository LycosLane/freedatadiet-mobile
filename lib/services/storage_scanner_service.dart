import 'dart:io' show Directory, File, FileSystemEntity, FileSystemEntityType, Link;
import 'dart:isolate';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/duplicate_rule.dart';
import '../models/storage_item.dart';
import 'duplicate_finder_service.dart';

/// Request payload for scanning a directory in a background isolate.
class _ScanRequest {
  final List<String> rootPaths;
  final bool includeSubfolders;
  final bool showHidden;
  final List<String> excludedPatterns;
  final DuplicateMatchCriteria duplicateCriteria;
  final SendPort sendPort;

  const _ScanRequest({
    required this.rootPaths,
    required this.includeSubfolders,
    required this.showHidden,
    required this.excludedPatterns,
    required this.duplicateCriteria,
    required this.sendPort,
  });
}

/// Service providing non-blocking parallel directory traversal.
class StorageScannerService {
  StorageScannerService._();

  /// Scans either immediate directory children or all nested files recursively.
  static Future<List<StorageItem>> scanDirectory({
    required List<String> paths,
    required bool includeSubfolders,
    required bool showHidden,
    required List<String> excludedPatterns,
    required DuplicateMatchCriteria duplicateCriteria,
  }) async {
    if (kIsWeb) {
      final webItems = _generateWebDemoItems(includeSubfolders, showHidden);
      if (includeSubfolders) {
        return DuplicateFinderService.markDuplicates(
          items: webItems,
          criteria: duplicateCriteria,
        );
      }
      return webItems;
    }

    final receivePort = ReceivePort();

    final request = _ScanRequest(
      rootPaths: paths,
      includeSubfolders: includeSubfolders,
      showHidden: showHidden,
      excludedPatterns: excludedPatterns,
      duplicateCriteria: duplicateCriteria,
      sendPort: receivePort.sendPort,
    );

    await Isolate.spawn(_isolateWorker, request);
    final List<StorageItem> rawItems = await receivePort.first as List<StorageItem>;
    receivePort.close();

    if (includeSubfolders) {
      return DuplicateFinderService.markDuplicates(
        items: rawItems,
        criteria: duplicateCriteria,
      );
    }

    return rawItems;
  }

  /// Worker function executed in the background isolate on native platforms.
  static void _isolateWorker(_ScanRequest request) {
    final List<StorageItem> results = [];

    for (final rootPath in request.rootPaths) {
      final rootDir = Directory(rootPath);
      if (!rootDir.existsSync()) continue;

      if (request.includeSubfolders) {
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

  /// Permanently deletes a list of files or directories.
  static Future<int> deleteItems(List<String> paths) async {
    if (kIsWeb) {
      _webDeletedPaths.addAll(paths);
      return paths.length;
    }

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

  static final Set<String> _webDeletedPaths = {};

  static List<StorageItem> _generateWebDemoItems(bool includeSubfolders, bool showHidden) {
    final now = DateTime.now();

    final allDemo = <StorageItem>[
      // Directories (visible when not including subfolders)
      if (!includeSubfolders) ...[
        StorageItem(
          path: '/storage/emulated/0/DCIM',
          name: 'DCIM',
          isDirectory: true,
          size: 24 * 1024 * 1024 * 1024 + 800 * 1024 * 1024,
          childCount: 1420,
          lastModified: now.subtract(const Duration(hours: 2)),
        ),
        StorageItem(
          path: '/storage/emulated/0/Movies',
          name: 'Movies',
          isDirectory: true,
          size: 18 * 1024 * 1024 * 1024 + 500 * 1024 * 1024,
          childCount: 24,
          lastModified: now.subtract(const Duration(days: 3)),
        ),
        StorageItem(
          path: '/storage/emulated/0/Download',
          name: 'Download',
          isDirectory: true,
          size: 14 * 1024 * 1024 * 1024 + 200 * 1024 * 1024,
          childCount: 312,
          lastModified: now.subtract(const Duration(minutes: 45)),
        ),
        StorageItem(
          path: '/storage/emulated/0/Documents',
          name: 'Documents',
          isDirectory: true,
          size: 3 * 1024 * 1024 * 1024 + 400 * 1024 * 1024,
          childCount: 88,
          lastModified: now.subtract(const Duration(days: 1)),
        ),
        if (showHidden)
          StorageItem(
            path: '/storage/emulated/0/.thumbnails',
            name: '.thumbnails',
            isDirectory: true,
            size: 2 * 1024 * 1024 * 1024 + 100 * 1024 * 1024,
            childCount: 5200,
            isSystem: true,
            lastModified: now.subtract(const Duration(days: 5)),
          ),
      ],

      // Nested files
      StorageItem(
        path: '/storage/emulated/0/Movies/Drone_4K_Flight_Cinematic.mp4',
        name: 'Drone_4K_Flight_Cinematic.mp4',
        isDirectory: false,
        size: 4 * 1024 * 1024 * 1024 + 820 * 1024 * 1024,
        extension: '.mp4',
        lastModified: now.subtract(const Duration(days: 4)),
      ),
      StorageItem(
        path: '/storage/emulated/0/Download/Full_System_Backup_2026.zip',
        name: 'Full_System_Backup_2026.zip',
        isDirectory: false,
        size: 3 * 1024 * 1024 * 1024 + 450 * 1024 * 1024,
        extension: '.zip',
        lastModified: now.subtract(const Duration(days: 8)),
      ),
      StorageItem(
        path: '/storage/emulated/0/Download/Financial_Audit_Report_2026.pdf',
        name: 'Financial_Audit_Report_2026.pdf',
        isDirectory: false,
        size: 485 * 1024 * 1024,
        extension: '.pdf',
        lastModified: DateTime(2026, 10, 15, 14, 30),
      ),
      StorageItem(
        path: '/storage/1A2B-3C4D/Documents/Financial_Audit_Report_2026.pdf',
        name: 'Financial_Audit_Report_2026.pdf',
        isDirectory: false,
        size: 485 * 1024 * 1024,
        extension: '.pdf',
        lastModified: DateTime(2026, 10, 15, 14, 30),
      ),
      StorageItem(
        path: '/storage/emulated/0/Music/Uncut_Podcast_Episode_12.wav',
        name: 'Uncut_Podcast_Episode_12.wav',
        isDirectory: false,
        size: 1 * 1024 * 1024 * 1024 + 200 * 1024 * 1024,
        extension: '.wav',
        lastModified: now.subtract(const Duration(days: 2)),
      ),
      StorageItem(
        path: '/storage/emulated/0/Download/temp_cache_blob_789.tmp',
        name: 'temp_cache_blob_789.tmp',
        isDirectory: false,
        size: 420 * 1024 * 1024,
        extension: '.tmp',
        lastModified: now.subtract(const Duration(days: 12)),
      ),
      StorageItem(
        path: '/storage/emulated/0/DCIM/Photo_RAW_DNG_0492.dng',
        name: 'Photo_RAW_DNG_0492.dng',
        isDirectory: false,
        size: 85 * 1024 * 1024,
        extension: '.dng',
        lastModified: now.subtract(const Duration(days: 1)),
      ),
      StorageItem(
        path: '/storage/emulated/0/DCIM/Photo_RAW_DNG_0492.xmp',
        name: 'Photo_RAW_DNG_0492.xmp',
        isDirectory: false,
        size: 12 * 1024,
        extension: '.xmp',
        lastModified: now.subtract(const Duration(days: 1)),
      ),
    ];

    return allDemo.where((item) => !_webDeletedPaths.contains(item.path)).toList();
  }
}

class _DirStats {
  final int totalSize;
  final int itemCount;
  const _DirStats({required this.totalSize, required this.itemCount});
}
