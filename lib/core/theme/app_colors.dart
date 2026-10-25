import 'package:flutter/material.dart';

/// Defines color constants aligned with the official FreeDataDiet White Fedora aesthetic.
class AppColors {
  AppColors._();

  // Dark Theme Palette (Obsidian background matching logo #101216)
  static const Color darkBackground = Color(0xFF101216);
  static const Color darkSurface = Color(0xFF171A21);
  static const Color darkCard = Color(0xFF1E222B);
  static const Color darkDivider = Color(0xFF2B313E);
  static const Color darkTextPrimary = Color(0xFFECEFF4);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Bright / Light Theme Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Official Brand Colors (White Fedora Ribbon Identity)
  static const Color brandCyan = Color(0xFF00B4FF);
  static const Color brandOrange = Color(0xFFFFB020);
  static const Color brandWhite = Color(0xFFFFFFFF);

  // Accents & Indicators
  static const Color primary = Color(0xFF0098E0);
  static const Color primaryLight = Color(0xFF00B4FF);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFFFB020);
  static const Color accentRose = Color(0xFFEF4444);

  // Badge Colors
  static const Color badgeDir = Color(0xFF00B4FF);
  static const Color badgeFile = Color(0xFF64748B);
  static const Color badgeSys = Color(0xFF8B5CF6);
  static const Color badgeLink = Color(0xFF38BDF8);
  static const Color badgeCache = Color(0xFFFFB020);

  // Proportional Usage Bar Gradient
  static LinearGradient usageBarGradient(double ratio) {
    if (ratio > 0.75) {
      return const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFF87171)],
      );
    } else if (ratio > 0.40) {
      return const LinearGradient(
        colors: [Color(0xFFFFB020), Color(0xFFF59E0B)],
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF00B4FF), Color(0xFF38BDF8)],
      );
    }
  }
}
