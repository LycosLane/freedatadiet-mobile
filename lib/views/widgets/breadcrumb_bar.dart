import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Renders an interactive path breadcrumb trail with parent navigation and bookmarking action.
class BreadcrumbBar extends StatelessWidget {
  final String currentPath;
  final ValueChanged<String> onNavigateTo;
  final VoidCallback onNavigateUp;
  final bool canNavigateUp;
  final bool isFavorite;
  final bool isStartup;
  final VoidCallback onBookmarkPressed;

  const BreadcrumbBar({
    super.key,
    required this.currentPath,
    required this.onNavigateTo,
    required this.onNavigateUp,
    required this.canNavigateUp,
    this.isFavorite = false,
    this.isStartup = false,
    required this.onBookmarkPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segments = currentPath.split('/').where((s) => s.isNotEmpty).toList();

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            onPressed: canNavigateUp ? onNavigateUp : null,
            tooltip: 'Navigate Up',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: segments.length,
              separatorBuilder: (_, _) => Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: theme.brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              itemBuilder: (context, index) {
                final isLast = index == segments.length - 1;
                final segmentPath = '/${segments.sublist(0, index + 1).join('/')}';
                final segmentName = segments[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: isLast ? null : () => onNavigateTo(segmentPath),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Center(
                      child: Text(
                        segmentName,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                          color: isLast
                              ? theme.colorScheme.primary
                              : (theme.brightness == Brightness.dark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 20,
              color: isFavorite ? AppColors.accentAmber : theme.hintColor,
            ),
            tooltip: isFavorite ? 'Bookmarked (Tap to manage)' : 'Bookmark this folder / Set as startup',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onBookmarkPressed,
          ),
        ],
      ),
    );
  }
}
