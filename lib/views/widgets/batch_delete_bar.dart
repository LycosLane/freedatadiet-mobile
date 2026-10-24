import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/size_formatter.dart';

/// Floating bottom action bar during Selection Mode.
class BatchDeleteBar extends StatelessWidget {
  final int selectedCount;
  final int selectedTotalBytes;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onDeletePressed;
  final VoidCallback onCancelSelection;

  const BatchDeleteBar({
    super.key,
    required this.selectedCount,
    required this.selectedTotalBytes,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onDeletePressed,
    required this.onCancelSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = selectedCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: onCancelSelection,
              tooltip: 'Exit Selection Mode',
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$selectedCount items selected',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    SizeFormatter.formatBytes(selectedTotalBytes),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: hasSelection ? AppColors.accentRose : theme.hintColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: selectedCount == 0 ? onSelectAll : onDeselectAll,
              child: Text(selectedCount == 0 ? 'Select All' : 'Clear'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: hasSelection ? onDeletePressed : null,
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text('Delete'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.accentRose.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
