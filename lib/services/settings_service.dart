import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/duplicate_rule.dart';
import '../models/user_settings.dart';

/// Manages loading and saving persistent user settings.
class SettingsService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyBarScaling = 'bar_scaling';
  static const String _keyShowHidden = 'show_hidden';
  static const String _keyIncludeSubfolders = 'include_subfolders';
  static const String _keyDupMatchSize = 'dup_match_size';
  static const String _keyDupMatchName = 'dup_match_name';
  static const String _keyDupMatchTimestamp = 'dup_match_timestamp';
  static const String _keySortColumn = 'sort_column';
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
    final includeSubfolders = prefs.getBool(_keyIncludeSubfolders) ?? false;

    final matchSize = prefs.getBool(_keyDupMatchSize) ?? true;
    final matchName = prefs.getBool(_keyDupMatchName) ?? true;
    final matchTimestamp = prefs.getBool(_keyDupMatchTimestamp) ?? false;

    final sortColIndex = prefs.getInt(_keySortColumn) ?? SortColumn.size.index;
    final sortColumn = SortColumn.values.elementAtOrNull(sortColIndex) ?? SortColumn.size;

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
      includeSubfolders: includeSubfolders,
      duplicateCriteria: DuplicateMatchCriteria(
        matchSize: matchSize,
        matchName: matchName,
        matchTimestamp: matchTimestamp,
      ),
      sortColumn: sortColumn,
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
    await prefs.setBool(_keyIncludeSubfolders, settings.includeSubfolders);
    await prefs.setBool(_keyDupMatchSize, settings.duplicateCriteria.matchSize);
    await prefs.setBool(_keyDupMatchName, settings.duplicateCriteria.matchName);
    await prefs.setBool(_keyDupMatchTimestamp, settings.duplicateCriteria.matchTimestamp);
    await prefs.setInt(_keySortColumn, settings.sortColumn.index);
    await prefs.setBool(_keySortDescending, settings.sortDescending);
    await prefs.setStringList(_keyExclusions, settings.excludedPatterns);
  }
}
