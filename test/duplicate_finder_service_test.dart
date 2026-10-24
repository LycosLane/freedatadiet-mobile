import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/models/duplicate_rule.dart';
import 'package:freedatadiet_mobile/models/storage_item.dart';
import 'package:freedatadiet_mobile/services/duplicate_finder_service.dart';

void main() {
  group('DuplicateFinderService Tests', () {
    final now = DateTime.now();

    final file1 = StorageItem(
      path: '/storage/Download/report.pdf',
      name: 'report.pdf',
      isDirectory: false,
      size: 1024 * 500, // 500 KB
      lastModified: now,
    );

    final file2 = StorageItem(
      path: '/storage/Documents/report.pdf',
      name: 'report.pdf',
      isDirectory: false,
      size: 1024 * 500, // exact same size & name
      lastModified: now,
    );

    final file3 = StorageItem(
      path: '/storage/DCIM/photo.jpg',
      name: 'photo.jpg',
      isDirectory: false,
      size: 1024 * 200,
      lastModified: now,
    );

    test('detects duplicates by name and size', () {
      final items = [file1, file2, file3];
      final tagged = DuplicateFinderService.markDuplicates(
        items: items,
        criteria: const DuplicateMatchCriteria(
          matchName: true,
          matchSize: true,
        ),
      );

      final dups = tagged.where((i) => i.isDuplicate).toList();
      expect(dups.length, 2);
      expect(dups[0].duplicateGroupId, isNotNull);
      expect(dups[0].duplicateGroupId, equals(dups[1].duplicateGroupId));

      final nonDup = tagged.firstWhere((i) => i.path == file3.path);
      expect(nonDup.isDuplicate, false);
      expect(nonDup.duplicateGroupId, isNull);
    });

    test('handles size only duplicate mode', () {
      final renamedClone = StorageItem(
        path: '/storage/Backup/report_copy.pdf',
        name: 'report_copy.pdf',
        isDirectory: false,
        size: 1024 * 500, // same size, different name
      );

      final items = [file1, renamedClone];
      final tagged = DuplicateFinderService.markDuplicates(
        items: items,
        criteria: const DuplicateMatchCriteria(
          matchName: false,
          matchSize: true,
        ),
      );

      expect(tagged.every((i) => i.isDuplicate), true);
    });

    test('two-pass hash verification distinguishes identical size but different content', () async {
      final tempDir = Directory.systemTemp.createTempSync('hash_dup_test_');
      try {
        final fA = File('${tempDir.path}/a.bin');
        final fB = File('${tempDir.path}/b.bin');
        final fC = File('${tempDir.path}/c.bin');

        // fA and fB have identical 5000 bytes
        final bytesSame = List<int>.generate(5000, (i) => i % 256);
        // fC has exact same length but different bytes at the end
        final bytesDiff = List<int>.generate(5000, (i) => (i + 1) % 256);

        fA.writeAsBytesSync(bytesSame);
        fB.writeAsBytesSync(bytesSame);
        fC.writeAsBytesSync(bytesDiff);

        final items = [
          StorageItem(
            path: fA.path,
            name: 'a.bin',
            isDirectory: false,
            size: 5000,
          ),
          StorageItem(
            path: fB.path,
            name: 'b.bin',
            isDirectory: false,
            size: 5000,
          ),
          StorageItem(
            path: fC.path,
            name: 'c.bin',
            isDirectory: false,
            size: 5000,
          ),
        ];

        final verified = await DuplicateFinderService.verifyWithHashes(
          items: items,
          criteria: const DuplicateMatchCriteria(
            matchName: false,
            matchSize: true,
            verifyHash: true,
          ),
        );

        final dups = verified.where((i) => i.isDuplicate).toList();
        expect(dups.length, 2);
        expect(dups.map((i) => i.name), containsAll(['a.bin', 'b.bin']));
        expect(dups.map((i) => i.name), isNot(contains('c.bin')));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
