import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/duplicate_rule.dart';
import '../models/user_settings.dart';

/// Manages loading and saving persistent user settings.
class SettingsService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyBarScaling = 'bar_scaling';
  static const String _keyShowHidden = 'show_hidden';
  static const String _keyRecursiveView = 'recursive_view';
  static const String _keyDuplicateMode = 'duplicate_mode';
  static const String _keySortBy = 'sort_by';
  static const String _keySortDescending = 'sort_descending';
  static const String _keyExclusions = 'excluded_patterns';

  /// Loads saved settings or returns defaults.
  static Future<UserSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_keyThemeMode) ?? ThemeMode.dark.index;
    final themeMode = ThemeMode.values.elementAtOrNull(themeIndex) ?? ThemeMode.dark;

    final scalingIndex = prefs.getInt(_keyBarScaling) ?? BarScalingMode.largestItem.index;
    final barScaling = BarScalingMode.values.elementAtOrNull(scalingIndex) ?? BarScalingMode.largestItem;

    final showHidden = prefs.getBool(_keyShowHidden) ?? false;
    final isRecursive = prefs.getBool(_keyRecursiveView) ?? false;

    final dupIndex = prefs.getInt(_keyDuplicateMode) ?? DuplicateMatchMode.nameAndSize.index;
    final duplicateMode = DuplicateMatchMode.values.elementAtOrNull(dupIndex) ?? DuplicateMatchMode.nameAndSize;

    final sortByIndex = prefs.getInt(_keySortBy) ?? SortByField.size.index;
    final sortBy = SortByField.values.elementAtOrNull(sortByIndex) ?? SortByField.size;

    final sortDesc = prefs.getBool(_keySortDescending) ?? true;

    final exclusions = prefs.getStringList(_keyExclusions) ?? [
      '.git',
      '.thumbnails',
      '.cache',
      'Android/data',
    ];

    return UserSettings(
      themeMode: themeMode,
      barScalingMode: barScaling,
      showHiddenFiles: showHidden,
      isRecursiveFlatView: isRecursive,
      duplicateMatchMode: duplicateMode,
      sortBy: sortBy,
      sortDescending: sortDesc,
      excludedPatterns: exclusions,
    );
  }

  /// Saves updated settings.
  static Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, settings.themeMode.index);
    await prefs.setInt(_keyBarScaling, settings.barScalingMode.index);
    await prefs.setBool(_keyShowHidden, settings.showHiddenFiles);
    await prefs.setBool(_keyRecursiveView, settings.isRecursiveFlatView);
    await prefs.setInt(_keyDuplicateMode, settings.duplicateMatchMode.index);
    await prefs.setInt(_keySortBy, settings.sortBy.index);
    await prefs.setBool(_keySortDescending, settings.sortDescending);
    await prefs.setStringList(_keyExclusions, settings.excludedPatterns);
  }
}
