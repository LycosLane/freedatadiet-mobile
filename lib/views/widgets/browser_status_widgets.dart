import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Banner shown while "Include subfolders" is active, with a progress bar during the scan.
class SubfolderBanner extends StatelessWidget {
  final bool isScanning;
  final int visibleCount;

  const SubfolderBanner({
    super.key,
    required this.isScanning,
    required this.visibleCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          color: AppColors.primary.withValues(alpha: 0.12),
          child: Row(
            children: [
              const Icon(
                Icons.folder_copy_rounded,
                size: 15,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isScanning
                      ? 'Scanning subfolders... results appear as they are found'
                      : 'Including subfolders: showing all nested files',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '$visibleCount files',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (isScanning) const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }
}

/// Hint shown when some folders could not be read, so the shown sizes are lower bounds.
class UnreadableNote extends StatelessWidget {
  const UnreadableNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      color: AppColors.accentAmber.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.accentAmber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Some folders could not be read. Their sizes may be higher.',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered icon, title, optional hint and optional action (empty and error states).
class CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const CenteredMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.hintColor.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: theme.hintColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor, fontSize: 12.5),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
