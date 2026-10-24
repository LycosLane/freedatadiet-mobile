import 'package:flutter/material.dart';

import '../../models/storage_item.dart';
import '../../services/subfolder_grouper.dart';
import 'subfolder_group_card.dart';

/// Renders the list of grouped entries when recursively browsing subfolders.
class SubfolderDiffListView extends StatelessWidget {
  final List<SubfolderEntry> entries;
  final Set<String> selectedPaths;
  final bool isSelectionMode;
  final double textScale;
  final void Function(String path) onToggleSelection;
  final void Function(SubfolderEntry entry) onSelectAllInGroup;
  final void Function(SubfolderEntry entry) onKeepFirstInGroup;
  final void Function(StorageItem item) onItemTap;
  final void Function(StorageItem item) onItemLongPress;
  final Future<void> Function() onRefresh;

  const SubfolderDiffListView({
    super.key,
    required this.entries,
    required this.selectedPaths,
    required this.isSelectionMode,
    required this.textScale,
    required this.onToggleSelection,
    required this.onSelectAllInGroup,
    required this.onKeepFirstInGroup,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return SubfolderGroupCard(
            key: ValueKey(entry.key),
            entry: entry,
            selectedPaths: selectedPaths,
            isSelectionMode: isSelectionMode,
            textScale: textScale,
            onToggleSelection: onToggleSelection,
            onSelectAllInGroup: onSelectAllInGroup,
            onKeepFirstInGroup: onKeepFirstInGroup,
            onItemTap: onItemTap,
            onItemLongPress: onItemLongPress,
          );
        },
      ),
    );
  }
}
