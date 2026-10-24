import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/duplicate_rule.dart';
import '../models/saved_location.dart';
import '../models/user_settings.dart';

/// Manages loading and saving persistent user settings.
class SettingsService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyBarScaling = 'bar_scaling';
  static const String _keySortColumn = 'sort_column';
  static const String _keySortDescending = 'sort_descending';
  static const String _keyExclusions = 'excluded_patterns';

  static const String _keyTextScale = 'text_scale';
  static const String _keyCustomFilter = 'custom_filter';

  // "What's Shown" - Opt-out visibility toggles
  static const String _keyShowImages = 'show_images';
  static const String _keyShowVideos = 'show_videos';
  static const String _keyShowAudio = 'show_audio';
  static const String _keyShowDocuments = 'show_documents';
  static const String _keyShowArchives = 'show_archives';
  static const String _keyIncludeSubfolders = 'include_subfolders';
  static const String _keyShowHidden = 'show_hidden';

  // Independent Duplicate Detection
  static const String _keyShowDupsOnly = 'show_dups_only';
  static const String _keyDupMatchSize = 'dup_match_size';
  static const String _keyDupMatchName = 'dup_match_name';
  static const String _keyDupMatchTimestamp = 'dup_match_timestamp';

  // Reorderable Locations & Favorites
  static const String _keyLocations = 'saved_locations_json';

  /// Loads saved settings or returns defaults.
  static Future<UserSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_keyThemeMode) ?? ThemeMode.dark.index;
    final themeMode = ThemeMode.values.elementAtOrNull(themeIndex) ?? ThemeMode.dark;

    final scalingIndex = prefs.getInt(_keyBarScaling) ?? BarScalingMode.largestItem.index;
    final barScaling = BarScalingMode.values.elementAtOrNull(scalingIndex) ?? BarScalingMode.largestItem;

    final sortColIndex = prefs.getInt(_keySortColumn) ?? SortColumn.size.index;
    final sortColumn = SortColumn.values.elementAtOrNull(sortColIndex) ?? SortColumn.size;
    final sortDesc = prefs.getBool(_keySortDescending) ?? true;

    final textScale = (prefs.getDouble(_keyTextScale) ?? 1.0).clamp(0.8, 1.6).toDouble();
    final customFilter = prefs.getString(_keyCustomFilter) ?? '';

    // "What's Shown" - Default is true for all categories!
    final showImages = prefs.getBool(_keyShowImages) ?? true;
    final showVideos = prefs.getBool(_keyShowVideos) ?? true;
    final showAudio = prefs.getBool(_keyShowAudio) ?? true;
    final showDocuments = prefs.getBool(_keyShowDocuments) ?? true;
    final showArchives = prefs.getBool(_keyShowArchives) ?? true;
    final includeSubfolders = prefs.getBool(_keyIncludeSubfolders) ?? false;
    final showHidden = prefs.getBool(_keyShowHidden) ?? false;

    // Duplicates
    final showDupsOnly = prefs.getBool(_keyShowDupsOnly) ?? false;
    final matchSize = prefs.getBool(_keyDupMatchSize) ?? true;
    final matchName = prefs.getBool(_keyDupMatchName) ?? true;
    final matchTimestamp = prefs.getBool(_keyDupMatchTimestamp) ?? false;

    // Locations & Favorites
    final locationsRaw = prefs.getString(_keyLocations);
    List<SavedLocation> locations = const [
      SavedLocation(id: 'internal', name: 'Internal Storage', path: '/storage/emulated/0', type: 'internal'),
      SavedLocation(id: 'fav_downloads', name: 'Downloads', path: '/storage/emulated/0/Download', type: 'favorite'),
      SavedLocation(id: 'fav_documents', name: 'Documents', path: '/storage/emulated/0/Documents', type: 'favorite'),
      SavedLocation(id: 'fav_dcim', name: 'Camera (DCIM)', path: '/storage/emulated/0/DCIM', type: 'favorite'),
      SavedLocation(id: 'apps_diet', name: 'Apps & Cache Diet', path: '', type: 'apps_diet'),
    ];

    if (locationsRaw != null) {
      try {
        final List<dynamic> list = jsonDecode(locationsRaw) as List<dynamic>;
        locations = list.map((item) => SavedLocation.fromMap(item as Map<String, dynamic>)).toList();
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
      sortColumn: sortColumn,
      sortDescending: sortDesc,
      excludedPatterns: exclusions,
      textScale: textScale,
      customFilterText: customFilter,
      showImages: showImages,
      showVideos: showVideos,
      showAudio: showAudio,
      showDocuments: showDocuments,
      showArchives: showArchives,
      includeSubfolders: includeSubfolders,
      showHiddenFiles: showHidden,
      showDuplicatesOnly: showDupsOnly,
      duplicateCriteria: DuplicateMatchCriteria(
        matchSize: matchSize,
        matchName: matchName,
        matchTimestamp: matchTimestamp,
      ),
      locations: locations,
    );
  }

  /// Saves updated settings.
  static Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, settings.themeMode.index);
    await prefs.setInt(_keyBarScaling, settings.barScalingMode.index);
    await prefs.setInt(_keySortColumn, settings.sortColumn.index);
    await prefs.setBool(_keySortDescending, settings.sortDescending);
    await prefs.setStringList(_keyExclusions, settings.excludedPatterns);

    await prefs.setDouble(_keyTextScale, settings.textScale);
    await prefs.setString(_keyCustomFilter, settings.customFilterText);

    await prefs.setBool(_keyShowImages, settings.showImages);
    await prefs.setBool(_keyShowVideos, settings.showVideos);
    await prefs.setBool(_keyShowAudio, settings.showAudio);
    await prefs.setBool(_keyShowDocuments, settings.showDocuments);
    await prefs.setBool(_keyShowArchives, settings.showArchives);
    await prefs.setBool(_keyIncludeSubfolders, settings.includeSubfolders);
    await prefs.setBool(_keyShowHidden, settings.showHiddenFiles);

    await prefs.setBool(_keyShowDupsOnly, settings.showDuplicatesOnly);
    await prefs.setBool(_keyDupMatchSize, settings.duplicateCriteria.matchSize);
    await prefs.setBool(_keyDupMatchName, settings.duplicateCriteria.matchName);
    await prefs.setBool(_keyDupMatchTimestamp, settings.duplicateCriteria.matchTimestamp);

    final locationsJson = jsonEncode(settings.locations.map((l) => l.toMap()).toList());
    await prefs.setString(_keyLocations, locationsJson);
  }
}
