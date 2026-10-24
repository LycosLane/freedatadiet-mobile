import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/size_formatter.dart';
import '../../models/storage_item.dart';
import '../../services/item_view_filter.dart';
import 'type_badge.dart';
import 'usage_bar.dart';

/// Renders a single row in the disk analyzer table.
class StorageItemTile extends StatelessWidget {
  final StorageItem item;
  final double ratio;
  final bool isSelectionMode;
  final bool isSelected;
  final double textScale;
  final ValueChanged<bool?>? onSelectChanged;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final void Function(Offset globalPosition)? onDragStart;
  final void Function(Offset globalPosition)? onDragUpdate;
  final VoidCallback? onDragEnd;

  const StorageItemTile({
    super.key,
    required this.item,
    required this.ratio,
    required this.isSelectionMode,
    required this.isSelected,
    this.textScale = 1.0,
    this.onSelectChanged,
    required this.onTap,
    this.onLongPress,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final dateColWidth = 85.0 * textScale.clamp(0.9, 1.3);
    final sizeColWidth = 78.0 * textScale.clamp(0.9, 1.3);
    final verticalPad = (7.0 * textScale.clamp(0.8, 1.4)).roundToDouble();
    final isImg = !item.isDirectory && ItemViewFilter.isImage(item.path);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: onDragStart != null
          ? (d) => onDragStart!(d.globalPosition)
          : null,
      onLongPressMoveUpdate: onDragUpdate != null
          ? (d) => onDragUpdate!(d.globalPosition)
          : null,
      onLongPressEnd: onDragEnd != null ? (_) => onDragEnd!() : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPad),
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
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: onDragStart != null
                          ? (d) => onDragStart!(d.globalPosition)
                          : null,
                      onVerticalDragUpdate: onDragUpdate != null
                          ? (d) => onDragUpdate!(d.globalPosition)
                          : null,
                      onVerticalDragEnd: onDragEnd != null
                          ? (_) => onDragEnd!()
                          : null,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: onSelectChanged,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (isImg) ...[
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 0.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(
                        File(item.path),
                        cacheWidth: 48,
                        cacheHeight: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.image_outlined,
                          size: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ],
                  TypeBadge(badge: item.badge),
                  const SizedBox(width: 8),
                  // Name Column
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: null,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: (13.0 * textScale).clamp(9.0, 22.0),
                              fontWeight: item.isDirectory
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (item.isScanning) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: (8.0 * textScale).clamp(7.0, 12.0),
                                  height: (8.0 * textScale).clamp(7.0, 12.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'scanning',
                                  style: TextStyle(
                                    fontSize: (9.0 * textScale).clamp(
                                      7.5,
                                      13.0,
                                    ),
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (item.isDuplicate) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentAmber.withValues(
                                alpha: 0.18,
                              ),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: AppColors.accentAmber.withValues(
                                  alpha: 0.6,
                                ),
                                width: 0.7,
                              ),
                            ),
                            child: Text(
                              item.duplicateGroupId != null
                                  ? 'DUP #${item.duplicateGroupId!.replaceFirst('dup_', '')}'
                                  : 'DUP',
                              style: TextStyle(
                                color: AppColors.accentAmber,
                                fontSize: (9.5 * textScale).clamp(7.5, 13.0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Date Column
                  SizedBox(
                    width: dateColWidth,
                    child: Text(
                      _formatDateOrChildCount(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: (11.0 * textScale).clamp(8.0, 17.0),
                        color: secondaryTextColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  // Size Column
                  SizedBox(
                    width: sizeColWidth,
                    child: item.isScanning && item.size == 0
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            // A running total (still scanning) or a size with unreadable parts is a lower bound.
                            '${item.isScanning || item.hasErrors ? '≥ ' : ''}${SizeFormatter.formatBytes(item.size)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: (12.5 * textScale).clamp(9.0, 19.0),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: item.isScanning
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.8,
                                    )
                                  : null,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              UsageBar(
                ratio: item.isScanning ? 0.05 : ratio,
                height: (3.5 * textScale.clamp(0.9, 1.3)).clamp(3.0, 6.0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateOrChildCount() {
    if (item.isScanning) {
      return 'calculating...';
    }
    if (item.isDirectory) {
      return '${item.childCount} items';
    }
    if (item.lastModified != null) {
      final d = item.lastModified!;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    return '';
  }
}
