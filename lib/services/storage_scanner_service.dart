import 'dart:io' show Directory, File, FileSystemEntity, FileSystemEntityType, Link;
import 'dart:isolate';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/duplicate_rule.dart';
import '../models/storage_item.dart';
import 'duplicate_finder_service.dart';

/// Update message sent from isolate when a folder's recursive size calculation finishes.
class FolderSizeUpdate {
  final String path;
  final int size;
  final int childCount;

  const FolderSizeUpdate({
    required this.path,
    required this.size,
    required this.childCount,
  });
}

/// Service providing non-blocking progressive directory traversal with live streaming.
class StorageScannerService {
  StorageScannerService._();

  /// Immediately returns shallow entries (< 5ms) so folders and files are visible at once,
  /// with subdirectories flagged as `isScanning: true`.
  static List<StorageItem> getImmediateShallowItems({
    required String path,
    required bool showHidden,
    required List<String> excludedPatterns,
  }) {
    if (kIsWeb) {
      return _generateWebDemoItems(false, showHidden);
    }

    final results = <StorageItem>[];
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return results;

      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? entity.path;

        if (!showHidden && name.startsWith('.')) continue;
        if (_isExcluded(entity.path, excludedPatterns)) continue;

        if (entity is Directory) {
          results.add(StorageItem(
            path: entity.path,
            name: name,
            isDirectory: true,
            size: 0,
            childCount: 0,
            lastModified: _safeStatModified(entity),
            isSystem: name.startsWith('.') || name.toLowerCase() == 'android',
            isScanning: true, // flagged for background size calculation
          ));
        } else if (entity is File) {
          results.add(StorageItem(
            path: entity.path,
            name: name,
            isDirectory: false,
            size: _safeFileLength(entity),
            lastModified: _safeStatModified(entity),
            extension: _extractExtension(name),
            isScanning: false,
          ));
        } else if (entity is Link) {
          results.add(StorageItem(
            path: entity.path,
            name: name,
            isDirectory: false,
            size: 0,
            isLink: true,
            isScanning: false,
          ));
        }
      }
    } catch (_) {}

    return results;
  }

  /// Calculates sizes for a list of directory paths in a background isolate and streams results back.
  static Stream<FolderSizeUpdate> calculateFolderSizesProgressive({
    required List<String> dirPaths,
    required List<String> excludedPatterns,
  }) async* {
    if (kIsWeb || dirPaths.isEmpty) return;

    final receivePort = ReceivePort();

    await Isolate.spawn(_folderSizeWorker, {
      'paths': dirPaths,
      'excluded': excludedPatterns,
      'sendPort': receivePort.sendPort,
    });

    await for (final msg in receivePort) {
      if (msg == null) break; // completion sentinel
      if (msg is Map) {
        yield FolderSizeUpdate(
          path: msg['path'] as String,
          size: msg['size'] as int,
          childCount: msg['childCount'] as int,
        );
      }
    }
  }

  static void _folderSizeWorker(Map<String, dynamic> params) {
    final List<String> paths = params['paths'] as List<String>;
    final List<String> excluded = params['excluded'] as List<String>;
    final SendPort sendPort = params['sendPort'] as SendPort;

    for (final path in paths) {
      try {
        final dir = Directory(path);
        if (dir.existsSync()) {
          final stats = _computeFullRecursiveStats(dir, excluded);
          sendPort.send({
            'path': path,
            'size': stats.totalSize,
            'childCount': stats.itemCount,
          });
        }
      } catch (_) {}
    }

    sendPort.send(null); // signal done
  }

  /// Scans entire file trees recursively when "includeSubfolders" is active.
  static Future<List<StorageItem>> scanDeepRecursive({
    required List<String> rootPaths,
    required bool showHidden,
    required List<String> excludedPatterns,
    required DuplicateMatchCriteria duplicateCriteria,
  }) async {
    if (kIsWeb) {
      final webItems = _generateWebDemoItems(true, showHidden);
      return DuplicateFinderService.markDuplicates(items: webItems, criteria: duplicateCriteria);
    }

    final receivePort = ReceivePort();

    await Isolate.spawn(_deepScanWorker, {
      'rootPaths': rootPaths,
      'showHidden': showHidden,
      'excluded': excludedPatterns,
      'sendPort': receivePort.sendPort,
    });

    final rawItems = await receivePort.first as List<StorageItem>;
    receivePort.close();

    return DuplicateFinderService.markDuplicates(
      items: rawItems,
      criteria: duplicateCriteria,
    );
  }

  static void _deepScanWorker(Map<String, dynamic> params) {
    final List<String> rootPaths = params['rootPaths'] as List<String>;
    final bool showHidden = params['showHidden'] as bool;
    final List<String> excluded = params['excluded'] as List<String>;
    final SendPort sendPort = params['sendPort'] as SendPort;

    final results = <StorageItem>[];

    for (final rootPath in rootPaths) {
      final rootDir = Directory(rootPath);
      if (!rootDir.existsSync()) continue;

      final stack = <Directory>[rootDir];
      while (stack.isNotEmpty) {
        final current = stack.removeLast();
        try {
          final entities = current.listSync(followLinks: false);
          for (final entity in entities) {
            final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? entity.path;

            if (!showHidden && name.startsWith('.')) continue;
            if (_isExcluded(entity.path, excluded)) continue;

            if (entity is Directory) {
              stack.add(entity);
            } else if (entity is File) {
              results.add(StorageItem(
                path: entity.path,
                name: name,
                isDirectory: false,
                size: _safeFileLength(entity),
                lastModified: _safeStatModified(entity),
                extension: _extractExtension(name),
                isScanning: false,
              ));
            }
          }
        } catch (_) {}
      }
    }

    sendPort.send(results);
  }

  static _DirStats _computeFullRecursiveStats(Directory dir, List<String> excludedPatterns) {
    int totalBytes = 0;
    int items = 0;
    final stack = <Directory>[dir];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      try {
        final children = current.listSync(recursive: false, followLinks: false);
        for (final child in children) {
          if (_isExcluded(child.path, excludedPatterns)) continue;
          if (child is File) {
            totalBytes += _safeFileLength(child);
            items++;
          } else if (child is Directory) {
            stack.add(child);
            items++;
          }
        }
      } catch (_) {}
    }

    return _DirStats(totalSize: totalBytes, itemCount: items);
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
      if (!includeSubfolders) ...[
        StorageItem(
          path: '/storage/emulated/0/DCIM',
          name: 'DCIM',
          isDirectory: true,
          size: 24 * 1024 * 1024 * 1024 + 800 * 1024 * 1024,
          childCount: 1420,
          lastModified: now.subtract(const Duration(hours: 2)),
          isScanning: false,
        ),
        StorageItem(
          path: '/storage/emulated/0/Movies',
          name: 'Movies',
          isDirectory: true,
          size: 18 * 1024 * 1024 * 1024 + 500 * 1024 * 1024,
          childCount: 24,
          lastModified: now.subtract(const Duration(days: 3)),
          isScanning: false,
        ),
        StorageItem(
          path: '/storage/emulated/0/Download',
          name: 'Download',
          isDirectory: true,
          size: 14 * 1024 * 1024 * 1024 + 200 * 1024 * 1024,
          childCount: 312,
          lastModified: now.subtract(const Duration(minutes: 45)),
          isScanning: false,
        ),
        StorageItem(
          path: '/storage/emulated/0/Documents',
          name: 'Documents',
          isDirectory: true,
          size: 3 * 1024 * 1024 * 1024 + 400 * 1024 * 1024,
          childCount: 88,
          lastModified: now.subtract(const Duration(days: 1)),
          isScanning: false,
        ),
      ],
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
    ];

    return allDemo.where((item) => !_webDeletedPaths.contains(item.path)).toList();
  }
}

class _DirStats {
  final int totalSize;
  final int itemCount;
  const _DirStats({required this.totalSize, required this.itemCount});
}
