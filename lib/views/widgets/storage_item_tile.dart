import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/size_formatter.dart';
import '../../models/storage_item.dart';
import 'type_badge.dart';
import 'usage_bar.dart';

/// Renders a single row in the disk analyzer list.
class StorageItemTile extends StatelessWidget {
  final StorageItem item;
  final double ratio;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const StorageItemTile({
    super.key,
    required this.item,
    required this.ratio,
    required this.isSelectionMode,
    required this.isSelected,
    this.onSelectChanged,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.primary.withValues(alpha: 0.08))
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: onSelectChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                ],
                TypeBadge(badge: item.badge),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (item.isDuplicate) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.accentAmber.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: AppColors.accentAmber.withValues(alpha: 0.5),
                                  width: 0.6,
                                ),
                              ),
                              child: const Text(
                                'DUP',
                                style: TextStyle(
                                  color: AppColors.accentAmber,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildSubtitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      SizeFormatter.formatBytes(item.size),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      SizeFormatter.formatPercentage(ratio),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: secondaryTextColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            UsageBar(ratio: ratio, height: 3.5),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    if (item.isDirectory) {
      return '${item.childCount} items';
    }
    final parts = <String>[];
    if (item.extension.isNotEmpty) {
      parts.add(item.extension.toUpperCase().replaceAll('.', ''));
    }
    if (item.lastModified != null) {
      final date = item.lastModified!;
      parts.add('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
    }
    return parts.isEmpty ? 'File' : parts.join(' • ');
  }
}
