import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/models/storage_item.dart';
import 'package:freedatadiet_mobile/models/user_settings.dart';
import 'package:freedatadiet_mobile/services/subfolder_grouper.dart';

void main() {
  group('SubfolderGrouper Tests', () {
    final items = [
      const StorageItem(
        path: '/storage/emulated/0/DCIM/photo.jpg',
        name: 'photo.jpg',
        isDirectory: false,
        size: 2048,
        isDuplicate: true,
        duplicateGroupId: 'dup_1',
      ),
      const StorageItem(
        path: '/storage/emulated/0/Download/photo.jpg',
        name: 'photo.jpg',
        isDirectory: false,
        size: 2048,
        isDuplicate: true,
        duplicateGroupId: 'dup_1',
      ),
      const StorageItem(
        path: '/storage/emulated/0/Documents/notes.txt',
        name: 'notes.txt',
        isDirectory: false,
        size: 512,
      ),
    ];

    test('groups items with identical names in subfolder mode', () {
      final entries = SubfolderGrouper.group(
        items: items,
        settings: const UserSettings(
          includeSubfolders: true,
          sortColumn: SortColumn.name,
        ),
      );

      expect(entries.length, 2);
      final photoGroup = entries.firstWhere(
        (e) => e.commonValue == 'photo.jpg',
      );
      expect(photoGroup.isMultiOccurrence, isTrue);
      expect(photoGroup.occurrences.length, 2);
      expect(photoGroup.totalSize, 4096);

      final notesGroup = entries.firstWhere(
        (e) => e.commonValue == 'notes.txt',
      );
      expect(notesGroup.isMultiOccurrence, isFalse);
      expect(notesGroup.occurrences.length, 1);
    });

    test('multi-occurrences are placed on top when sorted', () {
      final entries = SubfolderGrouper.group(
        items: items,
        settings: const UserSettings(
          includeSubfolders: true,
          sortColumn: SortColumn.name,
        ),
      );

      expect(entries.first.isMultiOccurrence, isTrue);
    });
  });
}
