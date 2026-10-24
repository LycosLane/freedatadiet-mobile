import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/size_formatter.dart';
import '../../models/storage_item.dart';
import '../../services/item_view_filter.dart';
import '../../services/subfolder_grouper.dart';
import 'type_badge.dart';

/// Renders a grouped subfolder card showing common values in the header and
/// indented occurrences showing the differing directory paths below.
class SubfolderGroupCard extends StatefulWidget {
  final SubfolderEntry entry;
  final Set<String> selectedPaths;
  final bool isSelectionMode;
  final double textScale;
  final void Function(String path) onToggleSelection;
  final void Function(SubfolderEntry entry) onSelectAllInGroup;
  final void Function(SubfolderEntry entry) onKeepFirstInGroup;
  final void Function(StorageItem item) onItemTap;
  final void Function(StorageItem item) onItemLongPress;

  const SubfolderGroupCard({
    super.key,
    required this.entry,
    required this.selectedPaths,
    required this.isSelectionMode,
    required this.textScale,
    required this.onToggleSelection,
    required this.onSelectAllInGroup,
    required this.onKeepFirstInGroup,
    required this.onItemTap,
    required this.onItemLongPress,
  });

  @override
  State<SubfolderGroupCard> createState() => _SubfolderGroupCardState();
}

class _SubfolderGroupCardState extends State<SubfolderGroupCard> {
  bool _isExpanded = true;

  String _getDirectoryPath(String fullPath) {
    final slash = fullPath.lastIndexOf('/');
    if (slash == -1) return fullPath;
    return fullPath.substring(0, slash);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entry = widget.entry;
    final primary = entry.primaryItem;
    final isImg = !primary.isDirectory && ItemViewFilter.isImage(primary.path);

    // Single occurrence: render cleanly with path subtitle
    if (!entry.isMultiOccurrence) {
      final item = primary;
      final isSelected = widget.selectedPaths.contains(item.path);

      return InkWell(
        onTap: () => widget.onItemTap(item),
        onLongPress: () => widget.onItemLongPress(item),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => widget.onToggleSelection(item.path),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
              ],
              if (isImg) ...[
                _buildThumbnail(item.path, theme),
                const SizedBox(width: 6),
              ],
              TypeBadge(badge: item.badge),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: null,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: (13.0 * widget.textScale).clamp(9.0, 22.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getDirectoryPath(item.path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: (10.5 * widget.textScale).clamp(8.0, 15.0),
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                SizeFormatter.formatBytes(item.size),
                style: TextStyle(
                  fontSize: (12.5 * widget.textScale).clamp(9.0, 19.0),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Multi-occurrence group card
    final selectedInGroupCount = entry.occurrences
        .where((i) => widget.selectedPaths.contains(i.path))
        .length;
    final allInGroupSelected = selectedInGroupCount == entry.occurrences.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222A) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: entry.isDuplicateCluster
              ? AppColors.accentAmber.withValues(alpha: 0.5)
              : theme.dividerColor,
          width: entry.isDuplicateCluster ? 1.0 : 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Group Header (Common Values)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  if (widget.isSelectionMode) ...[
                    Checkbox(
                      value: allInGroupSelected
                          ? true
                          : (selectedInGroupCount > 0 ? null : false),
                      tristate: true,
                      onChanged: (_) => widget.onSelectAllInGroup(entry),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (isImg) ...[
                    _buildThumbnail(primary.path, theme),
                    const SizedBox(width: 6),
                  ],
                  TypeBadge(badge: primary.badge),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.commonValue,
                          maxLines: null,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: (13.5 * widget.textScale).clamp(
                              9.5,
                              22.0,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (entry.isDuplicateCluster
                                            ? AppColors.accentAmber
                                            : theme.colorScheme.primary)
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${entry.occurrences.length} copies',
                                style: TextStyle(
                                  fontSize: 10.0 * widget.textScale,
                                  fontWeight: FontWeight.bold,
                                  color: entry.isDuplicateCluster
                                      ? AppColors.accentAmber
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              SizeFormatter.formatBytes(entry.totalSize),
                              style: TextStyle(
                                fontSize: 11.0 * widget.textScale,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (entry.isDuplicateCluster)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => widget.onKeepFirstInGroup(entry),
                      child: Text(
                        'Keep 1st',
                        style: TextStyle(
                          fontSize: (11.0 * widget.textScale).clamp(9.0, 14.0),
                          color: AppColors.accentAmber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ],
              ),
            ),
          ),

          // Indented Occurrences (Differing Paths)
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
            ...entry.occurrences.asMap().entries.map((indexedItem) {
              final idx = indexedItem.key;
              final item = indexedItem.value;
              final isSelected = widget.selectedPaths.contains(item.path);

              return InkWell(
                onTap: () {
                  if (widget.isSelectionMode) {
                    widget.onToggleSelection(item.path);
                  } else {
                    widget.onItemTap(item);
                  }
                },
                onLongPress: () => widget.onItemLongPress(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.18)
                              : AppColors.primary.withValues(alpha: 0.08))
                        : (idx % 2 == 1
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : Colors.black.withValues(alpha: 0.02))
                              : Colors.transparent),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => widget.onToggleSelection(item.path),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDirectoryPath(item.path),
                              maxLines: null,
                              softWrap: true,
                              style: TextStyle(
                                fontSize: (11.5 * widget.textScale).clamp(
                                  8.5,
                                  17.0,
                                ),
                                fontFamily: 'monospace',
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                            if (item.lastModified != null)
                              Text(
                                '${item.lastModified!.year}-${item.lastModified!.month.toString().padLeft(2, '0')}-${item.lastModified!.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10.0 * widget.textScale,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        SizeFormatter.formatBytes(item.size),
                        style: TextStyle(
                          fontSize: (11.5 * widget.textScale).clamp(8.5, 17.0),
                          fontFamily: 'monospace',
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnail(String path, ThemeData theme) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.file(
        File(path),
        cacheWidth: 48,
        cacheHeight: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.image_outlined, size: 14, color: Colors.white54),
      ),
    );
  }
}
