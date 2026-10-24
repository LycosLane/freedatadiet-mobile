import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/models/storage_item.dart';
import 'package:freedatadiet_mobile/services/duplicate_assistant_service.dart';

void main() {
  group('DuplicateAssistantService Tests', () {
    final items = [
      // Duplicate Pair 1
      const StorageItem(
        path: '/storage/DCIM/photo1.jpg',
        name: 'photo1.jpg',
        isDirectory: false,
        size: 1000,
        isDuplicate: true,
        duplicateGroupId: 'dup_1',
      ),
      const StorageItem(
        path: '/storage/Download/photo1.jpg',
        name: 'photo1.jpg',
        isDirectory: false,
        size: 1000,
        isDuplicate: true,
        duplicateGroupId: 'dup_1',
      ),

      // Duplicate Pair 2
      const StorageItem(
        path: '/storage/DCIM/photo2.jpg',
        name: 'photo2.jpg',
        isDirectory: false,
        size: 2000,
        isDuplicate: true,
        duplicateGroupId: 'dup_2',
      ),
      const StorageItem(
        path: '/storage/Download/photo2.jpg',
        name: 'photo2.jpg',
        isDirectory: false,
        size: 2000,
        isDuplicate: true,
        duplicateGroupId: 'dup_2',
      ),
    ];

    test('returns null if no items selected', () {
      final suggestion = DuplicateAssistantService.findSuggestion(
        allItems: items,
        selectedPaths: const {},
      );
      expect(suggestion, isNull);
    });

    test('suggests sibling duplicate in same folder when one is selected', () {
      // User selects Download copy of photo 1
      final suggestion = DuplicateAssistantService.findSuggestion(
        allItems: items,
        selectedPaths: {'/storage/Download/photo1.jpg'},
      );

      expect(suggestion, isNotNull);
      expect(suggestion!.directoryName, 'Download');
      expect(suggestion.count, 1);
      expect(suggestion.candidatePaths, ['/storage/Download/photo2.jpg']);
    });

    test('returns null when all copies in directory are already selected', () {
      final suggestion = DuplicateAssistantService.findSuggestion(
        allItems: items,
        selectedPaths: {
          '/storage/Download/photo1.jpg',
          '/storage/Download/photo2.jpg',
        },
      );

      expect(suggestion, isNull);
    });
  });
}
