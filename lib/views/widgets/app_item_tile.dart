import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/size_formatter.dart';
import '../../models/app_storage_info.dart';
import 'usage_bar.dart';

/// Renders a single row in the App Diet view with prominent Cache/Data metrics and 1-tap Settings navigation.
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallbackIcon(theme),
                        )
                      : _fallbackIcon(theme),
                ),
                const SizedBox(width: 12),
                // App Details & Breakdown
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
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (app.isSystemApp) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.badgeSys.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'SYSTEM',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.badgeSys,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Prominent Cache, Data, and APK labels
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _buildStatBadge(
                            label: 'Cache: ${SizeFormatter.formatBytes(app.cacheBytes)}',
                            color: isHeavyCache ? AppColors.accentRose : AppColors.accentAmber,
                            isBold: isHeavyCache,
                          ),
                          Text(
                            'Data: ${SizeFormatter.formatBytes(app.dataBytes)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'APK: ${SizeFormatter.formatBytes(app.appBytes)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Total Size & Arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      SizeFormatter.formatBytes(app.totalBytes),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: secondaryTextColor.withValues(alpha: 0.6),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          color: color,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _fallbackIcon(ThemeData theme) {
    return Container(
      width: 42,
      height: 42,
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: Icon(Icons.android_rounded, size: 24, color: theme.colorScheme.primary),
    );
  }
}
