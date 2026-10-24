import 'package:flutter/material.dart';

/// Defines color constants aligned with the FreeDataDiet desktop aesthetic.
class AppColors {
  AppColors._();

  // Dark Theme Palette (Charcoal / Slate desktop vibe)
  static const Color darkBackground = Color(0xFF181A1F);
  static const Color darkSurface = Color(0xFF21252B);
  static const Color darkCard = Color(0xFF282C34);
  static const Color darkDivider = Color(0xFF383C44);
  static const Color darkTextPrimary = Color(0xFFECEFF4);
  static const Color darkTextSecondary = Color(0xFF98A2B3);

  // Bright / Light Theme Palette
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Accents & Indicators
  static const Color primary = Color(0xFF2563EB); // Modern Royal Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF10B981); // Emerald size bar
  static const Color accentAmber = Color(
    0xFFF59E0B,
  ); // Large file / Cache warning
  static const Color accentRose = Color(
    0xFFEF4444,
  ); // Oversized bloat / Delete action

  // Badge Colors
  static const Color badgeDir = Color(0xFF3B82F6); // Blue for folders
  static const Color badgeFile = Color(0xFF6B7280); // Neutral grey for files
  static const Color badgeSys = Color(0xFF8B5CF6); // Purple for system
  static const Color badgeLink = Color(0xFF06B6D4); // Cyan for symlinks/links
  static const Color badgeCache = Color(0xFFF59E0B); // Amber for cache

  // Proportional Usage Bar Gradient
  static LinearGradient usageBarGradient(double ratio) {
    if (ratio > 0.75) {
      return const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFF87171)],
      );
    } else if (ratio > 0.40) {
      return const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      );
    }
  }
}
