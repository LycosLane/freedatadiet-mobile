import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/size_formatter.dart';
import '../../models/storage_item.dart';

/// Modal dialog confirming batch deletion with exact storage recovery metrics.
class DeleteConfirmDialog extends StatelessWidget {
  final List<StorageItem> selectedItems;
  final VoidCallback onConfirmDelete;

  const DeleteConfirmDialog({
    super.key,
    required this.selectedItems,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalReclaimedBytes = selectedItems.fold<int>(0, (sum, item) => sum + item.size);

    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: AppColors.accentRose, size: 24),
          SizedBox(width: 8),
          Text('Confirm Deletion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'Permanently delete '),
                  TextSpan(
                    text: '${selectedItems.length} selected items',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' to reclaim '),
                  TextSpan(
                    text: SizeFormatter.formatBytes(totalReclaimedBytes),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentRose,
                    ),
                  ),
                  const TextSpan(text: ' of disk space?'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: selectedItems.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: theme.dividerColor),
                  itemBuilder: (context, index) {
                    final item = selectedItems[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            SizeFormatter.formatBytes(item.size),
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirmDelete();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentRose,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete Permanently'),
        ),
      ],
    );
  }
}
