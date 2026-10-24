import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Renders a fixed-width type badge ([DIR], [FILE], [SYS], [LINK]) aligned like desktop FreeDataDiet.
class TypeBadge extends StatelessWidget {
  final String badge;

  const TypeBadge({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (badge) {
      case AppConstants.badgeDir:
        color = AppColors.badgeDir;
        break;
      case AppConstants.badgeSys:
        color = AppColors.badgeSys;
        break;
      case AppConstants.badgeLink:
        color = AppColors.badgeLink;
        break;
      default:
        color = AppColors.badgeFile;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        badge,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
