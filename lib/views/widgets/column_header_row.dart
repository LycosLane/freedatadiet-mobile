import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_settings.dart';

/// Table column header row inspired by the FreeDataDiet desktop app.
/// Allows tapping Name, Date, or Size to cycle sorting direction.
class ColumnHeaderRow extends StatelessWidget {
  final SortColumn activeColumn;
  final bool isDescending;
  final bool isSelectionMode;
  final double textScale;
  final Function(SortColumn column, bool descending) onSortChanged;

  const ColumnHeaderRow({
    super.key,
    required this.activeColumn,
    required this.isDescending,
    required this.isSelectionMode,
    this.textScale = 1.0,
    required this.onSortChanged,
  });

  void _handleColumnClick(SortColumn column) {
    if (activeColumn == column) {
      onSortChanged(column, !isDescending);
    } else {
      final defaultDesc = column != SortColumn.name;
      onSortChanged(column, defaultDesc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      height: 34 * textScale.clamp(0.9, 1.4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: headerColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (isSelectionMode) SizedBox(width: 32 * textScale),
          // Name Column Header
          Expanded(
            flex: 5,
            child: _buildHeaderCell(
              column: SortColumn.name,
              label: 'Name',
              alignment: Alignment.centerLeft,
              theme: theme,
            ),
          ),
          // Date Column Header
          SizedBox(
            width: 85 * textScale.clamp(0.9, 1.3),
            child: _buildHeaderCell(
              column: SortColumn.date,
              label: 'Date',
              alignment: Alignment.centerLeft,
              theme: theme,
            ),
          ),
          // Size Column Header
          SizedBox(
            width: 78 * textScale.clamp(0.9, 1.3),
            child: _buildHeaderCell(
              column: SortColumn.size,
              label: 'Size',
              alignment: Alignment.centerRight,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell({
    required SortColumn column,
    required String label,
    required Alignment alignment,
    required ThemeData theme,
  }) {
    final isActive = activeColumn == column;
    final isDark = theme.brightness == Brightness.dark;
    final activeTextColor = theme.colorScheme.primary;
    final defaultTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () => _handleColumnClick(column),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5 * textScale,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? activeTextColor : defaultTextColor,
              ),
            ),
            const SizedBox(width: 3),
            if (isActive)
              Icon(
                isDescending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 13 * textScale,
                color: activeTextColor,
              )
            else
              Icon(
                Icons.unfold_more_rounded,
                size: 12 * textScale,
                color: defaultTextColor.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}
