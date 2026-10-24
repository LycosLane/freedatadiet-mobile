import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/models/storage_item.dart';
import 'package:freedatadiet_mobile/services/deep_scan.dart';
import 'package:freedatadiet_mobile/services/file_delete_service.dart';
import 'package:freedatadiet_mobile/services/folder_size_scan.dart';
import 'package:freedatadiet_mobile/services/storage_scanner_service.dart';

/// Writes [bytes] zero bytes to [path], creating parent folders.
void _file(String path, int bytes) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(List.filled(bytes, 0));
}

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('fdd_scan_');
    _file('${root.path}/a/one.bin', 100);
    _file('${root.path}/a/sub/two.bin', 50);
    _file('${root.path}/b/three.bin', 10);
    _file('${root.path}/.git/objects', 999);
    _file('${root.path}/.github/workflow.yml', 7);
    _file('${root.path}/top.txt', 5);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('StorageScannerService.listDirectory', () {
    test('lists one level and flags folders as scanning', () {
      final listing = StorageScannerService.listDirectory(
        path: root.path,
        showHidden: false,
        excludedPatterns: const [],
      );
      expect(listing.pathExists, true);
      final names = listing.items.map((i) => i.name).toSet();
      expect(names, {'a', 'b', 'top.txt'});
      expect(
        listing.items.where((i) => i.isDirectory).every((i) => i.isScanning),
        true,
      );
    });

    test('hidden folders appear only when requested and exclusions match whole names', () {
      final listing = StorageScannerService.listDirectory(
        path: root.path,
        showHidden: true,
        excludedPatterns: const ['.git'],
      );
      final names = listing.items.map((i) => i.name).toSet();
      expect(names.contains('.git'), false);
      expect(names.contains('.github'), true);
    });

    test('reports a missing folder instead of an empty one', () {
      final listing = StorageScannerService.listDirectory(
        path: '${root.path}/does_not_exist',
        showHidden: false,
        excludedPatterns: const [],
      );
      expect(listing.pathExists, false);
    });

    test('listDirectoryAsync runs in background isolate safely', () async {
      final listing = await StorageScannerService.listDirectoryAsync(
        path: root.path,
        showHidden: false,
        excludedPatterns: const [],
      );
      expect(listing.pathExists, true);
      expect(listing.hadErrors, false);
      expect(listing.items.map((i) => i.name).toSet(), {'a', 'b', 'top.txt'});
    });
  });

  group('FolderSizeScan', () {
    test('streams a final size for every folder', () async {
      final scan = FolderSizeScan(
        dirPaths: ['${root.path}/a', '${root.path}/b'],
        excludedPatterns: const [],
      );
      final updates = scan.updates.toList();
      await scan.start();
      final all = await updates.timeout(const Duration(seconds: 10));

      final finals = {for (final u in all.where((u) => u.isFinal)) u.path: u};
      expect(finals['${root.path}/a']!.size, 150);
      expect(finals['${root.path}/a']!.childCount, 3); // one.bin, sub, two.bin
      expect(finals['${root.path}/b']!.size, 10);
      expect(finals.values.every((u) => !u.missing), true);
    });

    test('respects exclusions inside a folder', () async {
      final scan = FolderSizeScan(
        dirPaths: ['${root.path}/a'],
        excludedPatterns: const ['sub'],
      );
      final updates = scan.updates.toList();
      await scan.start();
      final all = await updates.timeout(const Duration(seconds: 10));
      expect(all.last.size, 100);
    });

    test('reports a vanished folder as missing', () async {
      final scan = FolderSizeScan(
        dirPaths: ['${root.path}/gone'],
        excludedPatterns: const [],
      );
      final updates = scan.updates.toList();
      await scan.start();
      final all = await updates.timeout(const Duration(seconds: 10));
      expect(all.single.missing, true);
      expect(all.single.isFinal, true);
    });

    test('cancel closes the stream', () async {
      final scan = FolderSizeScan(
        dirPaths: ['${root.path}/a', '${root.path}/b'],
        excludedPatterns: const [],
      );
      final done = scan.updates.toList();
      final started = scan.start();
      scan.cancel();
      await started;
      await done.timeout(const Duration(seconds: 10));
    });
  });

  group('DeepScan', () {
    test('finds all files and skips hidden ones by default', () async {
      final scan = DeepScan(
        rootPaths: [root.path],
        showHidden: false,
        excludedPatterns: const [],
      );
      final batches = scan.batches.toList();
      await scan.start();
      final all = await batches.timeout(const Duration(seconds: 10));

      final names = all.expand((b) => b.items).map((i) => i.name).toSet();
      expect(names, {'one.bin', 'two.bin', 'three.bin', 'top.txt'});
      expect(all.last.done, true);
      expect(all.last.rootMissing, false);
    });

    test('flags a missing root', () async {
      final scan = DeepScan(
        rootPaths: ['${root.path}/gone'],
        showHidden: false,
        excludedPatterns: const [],
      );
      final batches = scan.batches.toList();
      await scan.start();
      final all = await batches.timeout(const Duration(seconds: 10));
      expect(all.last.rootMissing, true);
    });
  });

  group('FileDeleteService', () {
    test('deletes files and folders and reports failures', () {
      final result = FileDeleteService.deleteSync([
        '${root.path}/a',
        '${root.path}/top.txt',
        '${root.path}/never_existed',
      ]);
      expect(result.deleted, 2);
      expect(result.failed, ['${root.path}/never_existed']);
      expect(Directory('${root.path}/a').existsSync(), false);
      expect(File('${root.path}/top.txt').existsSync(), false);
    });

    test('refuses protected paths', () {
      final result = FileDeleteService.deleteSync([
        '/storage/emulated/0',
        '/storage/emulated/0/Android',
      ]);
      expect(result.deleted, 0);
      expect(result.failed.length, 2);
    });

    test('async variant works off the calling isolate', () async {
      final result = await FileDeleteService.deleteItems(['${root.path}/b']);
      expect(result.deleted, 1);
      expect(Directory('${root.path}/b').existsSync(), false);
    });
  });

  test('StorageItem.copyWith can clear the duplicate group', () {
    const item = StorageItem(
      path: '/x',
      name: 'x',
      isDirectory: false,
      size: 1,
      isDuplicate: true,
      duplicateGroupId: 'dup_1',
    );
    final cleared = item.copyWith(
      isDuplicate: false,
      clearDuplicateGroup: true,
    );
    expect(cleared.duplicateGroupId, isNull);
  });
}
