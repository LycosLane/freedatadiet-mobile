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
      size: 1024 * 500, // exact same size
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
        mode: DuplicateMatchMode.nameAndSize,
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
        mode: DuplicateMatchMode.sizeOnly,
      );

      expect(tagged.every((i) => i.isDuplicate), true);
    });
  });
}
