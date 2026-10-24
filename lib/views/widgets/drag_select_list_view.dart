import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/storage_item.dart';
import 'storage_item_tile.dart';

/// Callback for when a drag-to-select operation updates the selected items.
typedef RangeSelectionCallback = void Function(Set<String> selectedPaths);

/// A ListView wrapper that provides Google Photos / Files style continuous Drag-to-Select.
///
/// Behavior:
/// - When [isSelectionMode] is true, pressing and dragging over items continuously selects them.
/// - Dragging from the checkbox on any tile triggers instant drag-selection.
/// - Long-pressing and dragging on any tile triggers drag-selection.
/// - Near the top or bottom edges of the list, auto-scrolling is triggered smoothly.
class DragSelectListView extends StatefulWidget {
  final List<StorageItem> items;
  final Set<String> selectedPaths;
  final bool isSelectionMode;
  final double textScale;
  final double Function(StorageItem) computeRatio;
  final void Function(String path) onToggleSelection;
  final RangeSelectionCallback onRangeSelection;
  final void Function(StorageItem item) onItemTap;
  final void Function(StorageItem item) onItemLongPress;
  final Future<void> Function() onRefresh;

  const DragSelectListView({
    super.key,
    required this.items,
    required this.selectedPaths,
    required this.isSelectionMode,
    required this.textScale,
    required this.computeRatio,
    required this.onToggleSelection,
    required this.onRangeSelection,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onRefresh,
  });

  @override
  State<DragSelectListView> createState() => _DragSelectListViewState();
}

class _DragSelectListViewState extends State<DragSelectListView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  // Drag state
  bool _isDragging = false;
  int? _dragStartIndex;
  int? _lastHoverIndex;
  bool _dragSelecting = true; // true = adding to selection, false = removing
  Set<String> _dragBaseSelection = {};

  Timer? _autoScrollTimer;
  double _lastPointerGlobalY = 0;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onDragStart(int index, Offset globalPosition) {
    if (!mounted || index < 0 || index >= widget.items.length) return;

    final item = widget.items[index];

    if (!widget.isSelectionMode) {
      widget.onItemLongPress(item);
    }

    final isAlreadySelected = widget.selectedPaths.contains(item.path);

    _isDragging = true;
    _dragStartIndex = index;
    _lastHoverIndex = index;
    _dragSelecting = !isAlreadySelected;
    _dragBaseSelection = Set<String>.from(widget.selectedPaths);
    _lastPointerGlobalY = globalPosition.dy;

    _updateSelectionForIndex(index);
    _checkAutoScroll(globalPosition);
  }

  void _onDragUpdate(Offset globalPosition) {
    if (!_isDragging || _dragStartIndex == null) return;
    _lastPointerGlobalY = globalPosition.dy;

    final index = _findItemIndexAt(globalPosition);
    if (index != null && index != _lastHoverIndex) {
      _lastHoverIndex = index;
      _updateSelectionForIndex(index);
    }

    _checkAutoScroll(globalPosition);
  }

  void _onDragEnd() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _isDragging = false;
    _dragStartIndex = null;
    _lastHoverIndex = null;
    _dragBaseSelection.clear();
  }

  void _updateSelectionForIndex(int currentIndex) {
    if (_dragStartIndex == null) return;

    final start = math.min(_dragStartIndex!, currentIndex);
    final end = math.max(_dragStartIndex!, currentIndex);

    final affectedPaths = <String>{};
    for (int i = start; i <= end; i++) {
      if (i >= 0 && i < widget.items.length) {
        affectedPaths.add(widget.items[i].path);
      }
    }

    final newSelection = Set<String>.from(_dragBaseSelection);
    if (_dragSelecting) {
      newSelection.addAll(affectedPaths);
    } else {
      newSelection.removeAll(affectedPaths);
    }

    widget.onRangeSelection(newSelection);
  }

  int? _findItemIndexAt(Offset globalPosition) {
    int? closestIndex;
    double? minDistance;

    for (final entry in _itemKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;

      final local = box.globalToLocal(globalPosition);
      if (local.dy >= 0 && local.dy < box.size.height) {
        return entry.key;
      }

      // Track distance to closest visible item in case the finger moved slightly off-bounds
      final dist = local.dy < 0 ? -local.dy : local.dy - box.size.height;
      if (minDistance == null || dist < minDistance) {
        minDistance = dist;
        closestIndex = entry.key;
      }
    }

    return closestIndex;
  }

  void _checkAutoScroll(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final local = renderBox.globalToLocal(globalPosition);
    const triggerDistance = 50.0;
    const maxScrollStep = 14.0;

    double scrollVelocity = 0.0;

    if (local.dy < triggerDistance) {
      // Near top of list
      final factor =
          (triggerDistance - local.dy).clamp(0.0, triggerDistance) /
          triggerDistance;
      scrollVelocity = -maxScrollStep * factor;
    } else if (local.dy > renderBox.size.height - triggerDistance) {
      // Near bottom of list
      final diff = local.dy - (renderBox.size.height - triggerDistance);
      final factor = diff.clamp(0.0, triggerDistance) / triggerDistance;
      scrollVelocity = maxScrollStep * factor;
    }

    if (scrollVelocity != 0.0) {
      if (_autoScrollTimer == null || !_autoScrollTimer!.isActive) {
        _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
          _,
        ) {
          if (!_isDragging || !_scrollController.hasClients) {
            _autoScrollTimer?.cancel();
            return;
          }

          final targetOffset = (_scrollController.offset + scrollVelocity)
              .clamp(0.0, _scrollController.position.maxScrollExtent);

          _scrollController.jumpTo(targetOffset);

          // Update selection for items newly revealed under pointer
          final index = _findItemIndexAt(Offset(0, _lastPointerGlobalY));
          if (index != null && index != _lastHoverIndex) {
            _lastHoverIndex = index;
            _updateSelectionForIndex(index);
          }
        });
      }
    } else {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final key = _itemKeys.putIfAbsent(index, () => GlobalKey());

          return StorageItemTile(
            key: key,
            item: item,
            ratio: widget.computeRatio(item),
            isSelectionMode: widget.isSelectionMode,
            isSelected: widget.selectedPaths.contains(item.path),
            textScale: widget.textScale,
            onSelectChanged: (_) => widget.onToggleSelection(item.path),
            onTap: () => widget.onItemTap(item),
            onLongPress: () => widget.onItemLongPress(item),
            onDragStart: (pos) => _onDragStart(index, pos),
            onDragUpdate: _onDragUpdate,
            onDragEnd: _onDragEnd,
          );
        },
      ),
    );
  }
}
