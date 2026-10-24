import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Renders a proportional horizontal usage bar representing relative size weight.
class UsageBar extends StatelessWidget {
  final double ratio;
  final double height;

  const UsageBar({super.key, required this.ratio, this.height = 4.0});

  @override
  Widget build(BuildContext context) {
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth * clampedRatio;

        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: barWidth,
            height: height,
            decoration: BoxDecoration(
              gradient: AppColors.usageBarGradient(clampedRatio),
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
      },
    );
  }
}
