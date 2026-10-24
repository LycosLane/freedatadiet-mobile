import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/models/storage_item.dart';
import 'package:freedatadiet_mobile/views/widgets/drag_select_list_view.dart';

void main() {
  group('DragSelectListView Widget Tests', () {
    final testItems = List.generate(
      5,
      (i) => StorageItem(
        path: '/storage/item_$i.txt',
        name: 'item_$i.txt',
        isDirectory: false,
        size: (i + 1) * 1000,
      ),
    );

    testWidgets('renders all items cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DragSelectListView(
              items: testItems,
              selectedPaths: const {},
              isSelectionMode: false,
              textScale: 1.0,
              computeRatio: (_) => 0.5,
              onToggleSelection: (_) {},
              onRangeSelection: (_) {},
              onItemTap: (_) {},
              onItemLongPress: (_) {},
              onRefresh: () async {},
            ),
          ),
        ),
      );

      expect(find.text('item_0.txt'), findsOneWidget);
      expect(find.text('item_4.txt'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('shows checkboxes in selection mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DragSelectListView(
              items: testItems,
              selectedPaths: {'/storage/item_1.txt'},
              isSelectionMode: true,
              textScale: 1.0,
              computeRatio: (_) => 0.5,
              onToggleSelection: (_) {},
              onRangeSelection: (_) {},
              onItemTap: (_) {},
              onItemLongPress: (_) {},
              onRefresh: () async {},
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsWidgets);
    });
  });
}
