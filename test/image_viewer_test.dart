import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/models/storage_item.dart';
import 'package:freedatadiet_mobile/services/item_view_filter.dart';
import 'package:freedatadiet_mobile/views/image_viewer_screen.dart';

void main() {
  group('ItemViewFilter.isImage', () {
    test('identifies common image extensions case-insensitively', () {
      expect(ItemViewFilter.isImage('/photos/vacation.jpg'), isTrue);
      expect(ItemViewFilter.isImage('/photos/vacation.JPEG'), isTrue);
      expect(ItemViewFilter.isImage('/photos/diagram.png'), isTrue);
      expect(ItemViewFilter.isImage('/photos/graphic.webp'), isTrue);
      expect(ItemViewFilter.isImage('/photos/camera.heic'), isTrue);
      expect(ItemViewFilter.isImage('/photos/camera.RAW'), isTrue);
      expect(ItemViewFilter.isImage('/photos/animation.gif'), isTrue);
      expect(ItemViewFilter.isImage('/photos/bitmap.bmp'), isTrue);
    });

    test('returns false for non-image files', () {
      expect(ItemViewFilter.isImage('/videos/clip.mp4'), isFalse);
      expect(ItemViewFilter.isImage('/docs/notes.pdf'), isFalse);
      expect(ItemViewFilter.isImage('/archives/backup.zip'), isFalse);
      expect(ItemViewFilter.isImage('/system/file_without_ext'), isFalse);
    });
  });

  group('ImageViewerScreen Widget Tests', () {
    testWidgets('renders empty state when no items provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ImageViewerScreen(items: [], initialIndex: 0)),
      );

      expect(find.text('No images to display'), findsOneWidget);
    });

    testWidgets('renders image title and counter', (tester) async {
      final items = [
        const StorageItem(
          path: '/mock/photo1.jpg',
          name: 'photo1.jpg',
          isDirectory: false,
          size: 1024 * 1024,
        ),
        const StorageItem(
          path: '/mock/photo2.png',
          name: 'photo2.png',
          isDirectory: false,
          size: 2 * 1024 * 1024,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(home: ImageViewerScreen(items: items, initialIndex: 0)),
      );

      expect(find.text('photo1.jpg'), findsOneWidget);
      expect(find.textContaining('1 of 2'), findsOneWidget);
    });
  });
}
