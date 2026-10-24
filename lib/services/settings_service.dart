import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/duplicate_rule.dart';
import '../models/favorite_folder.dart';
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

  static const String _keyTextScale = 'text_scale';
  static const String _keyCustomFilter = 'custom_filter';
  static const String _keyFilterImages = 'filter_images';
  static const String _keyFilterVideos = 'filter_videos';
  static const String _keyFilterAudio = 'filter_audio';
  static const String _keyFilterDocs = 'filter_docs';
  static const String _keyFilterArchives = 'filter_archives';
  static const String _keyShowDupsOnly = 'show_dups_only';
  static const String _keyFavorites = 'favorite_folders_json';
  static const String _keyStartupPath = 'startup_path';

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

    final textScale = prefs.getDouble(_keyTextScale) ?? 1.0;
    final customFilter = prefs.getString(_keyCustomFilter) ?? '';
    final filterImages = prefs.getBool(_keyFilterImages) ?? false;
    final filterVideos = prefs.getBool(_keyFilterVideos) ?? false;
    final filterAudio = prefs.getBool(_keyFilterAudio) ?? false;
    final filterDocs = prefs.getBool(_keyFilterDocs) ?? false;
    final filterArchives = prefs.getBool(_keyFilterArchives) ?? false;
    final showDupsOnly = prefs.getBool(_keyShowDupsOnly) ?? false;

    final startupPath = prefs.getString(_keyStartupPath) ?? '/storage/emulated/0';

    final favoritesRaw = prefs.getString(_keyFavorites);
    List<FavoriteFolder> favorites = const [
      FavoriteFolder(name: 'Downloads', path: '/storage/emulated/0/Download'),
      FavoriteFolder(name: 'Documents', path: '/storage/emulated/0/Documents'),
      FavoriteFolder(name: 'Camera (DCIM)', path: '/storage/emulated/0/DCIM'),
    ];
    if (favoritesRaw != null) {
      try {
        final List<dynamic> list = jsonDecode(favoritesRaw) as List<dynamic>;
        favorites = list.map((item) => FavoriteFolder.fromMap(item as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

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
      textScale: textScale,
      customFilterText: customFilter,
      filterImages: filterImages,
      filterVideos: filterVideos,
      filterAudio: filterAudio,
      filterDocuments: filterDocs,
      filterArchives: filterArchives,
      showDuplicatesOnly: showDupsOnly,
      favoriteFolders: favorites,
      defaultStartupPath: startupPath,
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

    await prefs.setDouble(_keyTextScale, settings.textScale);
    await prefs.setString(_keyCustomFilter, settings.customFilterText);
    await prefs.setBool(_keyFilterImages, settings.filterImages);
    await prefs.setBool(_keyFilterVideos, settings.filterVideos);
    await prefs.setBool(_keyFilterAudio, settings.filterAudio);
    await prefs.setBool(_keyFilterDocs, settings.filterDocuments);
    await prefs.setBool(_keyFilterArchives, settings.filterArchives);
    await prefs.setBool(_keyShowDupsOnly, settings.showDuplicatesOnly);

    await prefs.setString(_keyStartupPath, settings.defaultStartupPath);
    final favJson = jsonEncode(settings.favoriteFolders.map((f) => f.toMap()).toList());
    await prefs.setString(_keyFavorites, favJson);
  }
}
