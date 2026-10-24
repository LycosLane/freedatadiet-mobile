import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/size_formatter.dart';
import '../../models/app_storage_info.dart';
import 'usage_bar.dart';

/// Renders a single row in the App Diet view with Cache/Data breakdown and 1-tap Settings action.
class AppItemTile extends StatelessWidget {
  final AppStorageInfo app;
  final double ratio;
  final VoidCallback onOpenStorageSettings;

  const AppItemTile({
    super.key,
    required this.app,
    required this.ratio,
    required this.onOpenStorageSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isHeavyCache = app.cacheBytes > (250 * 1024 * 1024); // > 250 MB cache

    return InkWell(
      onTap: onOpenStorageSettings,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
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
                // App Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: app.iconBytes != null
                      ? Image.memory(
                          app.iconBytes!,
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallbackIcon(theme),
                        )
                      : _fallbackIcon(theme),
                ),
                const SizedBox(width: 10),
                // App Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (app.isSystemApp) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.badgeSys.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'SYSTEM',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.badgeSys,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildStatBadge(
                            label: 'Cache: ${SizeFormatter.formatBytes(app.cacheBytes)}',
                            color: isHeavyCache ? AppColors.accentRose : AppColors.accentAmber,
                            isBold: isHeavyCache,
                          ),
                          Text(
                            'Data: ${SizeFormatter.formatBytes(app.dataBytes)}',
                            style: TextStyle(fontSize: 11, color: secondaryTextColor),
                          ),
                          Text(
                            'APK: ${SizeFormatter.formatBytes(app.appBytes)}',
                            style: TextStyle(fontSize: 11, color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Total Size & Action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      SizeFormatter.formatBytes(app.totalBytes),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: onOpenStorageSettings,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: const Size(60, 26),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        side: BorderSide(
                          color: isHeavyCache
                              ? AppColors.accentRose.withValues(alpha: 0.7)
                              : theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        isHeavyCache ? 'Clean Cache' : 'Storage',
                        style: TextStyle(
                          color: isHeavyCache ? AppColors.accentRose : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            UsageBar(ratio: ratio, height: 3.5),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({required String label, required Color color, bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _fallbackIcon(ThemeData theme) {
    return Container(
      width: 38,
      height: 38,
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: Icon(Icons.android_rounded, size: 22, color: theme.colorScheme.primary),
    );
  }
}
