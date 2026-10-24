import 'package:flutter/material.dart';

import 'duplicate_rule.dart';
import 'saved_location.dart';

enum BarScalingMode {
  largestItem(
    'Largest Item in View',
    'Bars scale relative to the largest item visible.',
  ),
  folderTotal(
    'Current Folder Total',
    'Bars scale relative to the total size of the current folder.',
  ),
  driveTotal(
    'Total Disk Capacity',
    'Bars scale relative to the entire storage volume.',
  );

  final String label;
  final String description;

  const BarScalingMode(this.label, this.description);
}

enum SortColumn {
  name('Name'),
  date('Date'),
  size('Size');

  final String label;
  const SortColumn(this.label);
}

class UserSettings {
  /// Sensible folders to skip for everyone. Users can edit the list and restore these any time.
  static const List<String> defaultExcludedPatterns = [
    '.git',
    '.thumbnails',
    '.cache',
    'Android/data',
  ];

  final ThemeMode themeMode;
  final BarScalingMode barScalingMode;
  final SortColumn sortColumn;
  final bool sortDescending;
  final List<String> excludedPatterns;

  // Zoom / Font Scale
  final double textScale; // e.g. 0.8 to 1.6

  // Search & Extension Filter
  final String customFilterText;

  // "What's Shown" - Opt-out visibility toggles (all true by default)
  final bool showImages;
  final bool showVideos;
  final bool showAudio;
  final bool showDocuments;
  final bool showArchives;
  final bool includeSubfolders;
  final bool showHiddenFiles;

  // Independent Duplicate Filtering
  final bool showDuplicatesOnly;
  final DuplicateMatchCriteria duplicateCriteria;

  // Reorderable Locations & Favorites (Item at index 0 is default startup location)
  final List<SavedLocation> locations;

  const UserSettings({
    this.themeMode = ThemeMode.dark,
    this.barScalingMode = BarScalingMode.largestItem,
    this.sortColumn = SortColumn.size,
    this.sortDescending = true,
    this.excludedPatterns = defaultExcludedPatterns,
    this.textScale = 1.0,
    this.customFilterText = '',
    this.showImages = true,
    this.showVideos = true,
    this.showAudio = true,
    this.showDocuments = true,
    this.showArchives = true,
    this.includeSubfolders = false,
    this.showHiddenFiles = false,
    this.showDuplicatesOnly = false,
    this.duplicateCriteria = const DuplicateMatchCriteria(),
    this.locations = const [
      SavedLocation(
        id: 'internal',
        name: 'Internal Storage',
        path: '/storage/emulated/0',
        type: 'internal',
      ),
      SavedLocation(
        id: 'fav_downloads',
        name: 'Downloads',
        path: '/storage/emulated/0/Download',
        type: 'favorite',
      ),
      SavedLocation(
        id: 'fav_documents',
        name: 'Documents',
        path: '/storage/emulated/0/Documents',
        type: 'favorite',
      ),
      SavedLocation(
        id: 'fav_dcim',
        name: 'Camera (DCIM)',
        path: '/storage/emulated/0/DCIM',
        type: 'favorite',
      ),
      SavedLocation(
        id: 'apps_diet',
        name: 'Apps & Cache Diet',
        path: '',
        type: 'apps_diet',
      ),
    ],
  });

  /// True if the excluded-folder list differs from the defaults.
  bool get hasCustomExclusions {
    final a = excludedPatterns.map((e) => e.toLowerCase()).toSet();
    final b = defaultExcludedPatterns.map((e) => e.toLowerCase()).toSet();
    return a.length != b.length || !a.containsAll(b);
  }

  /// True if any non-default visibility filter or search is active.
  bool get hasActiveFilters =>
      !showImages ||
      !showVideos ||
      !showAudio ||
      !showDocuments ||
      !showArchives ||
      includeSubfolders ||
      showHiddenFiles ||
      showDuplicatesOnly ||
      customFilterText.trim().isNotEmpty;

  UserSettings copyWith({
    ThemeMode? themeMode,
    BarScalingMode? barScalingMode,
    SortColumn? sortColumn,
    bool? sortDescending,
    List<String>? excludedPatterns,
    double? textScale,
    String? customFilterText,
    bool? showImages,
    bool? showVideos,
    bool? showAudio,
    bool? showDocuments,
    bool? showArchives,
    bool? includeSubfolders,
    bool? showHiddenFiles,
    bool? showDuplicatesOnly,
    DuplicateMatchCriteria? duplicateCriteria,
    List<SavedLocation>? locations,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      barScalingMode: barScalingMode ?? this.barScalingMode,
      sortColumn: sortColumn ?? this.sortColumn,
      sortDescending: sortDescending ?? this.sortDescending,
      excludedPatterns: excludedPatterns ?? this.excludedPatterns,
      textScale: textScale ?? this.textScale,
      customFilterText: customFilterText ?? this.customFilterText,
      showImages: showImages ?? this.showImages,
      showVideos: showVideos ?? this.showVideos,
      showAudio: showAudio ?? this.showAudio,
      showDocuments: showDocuments ?? this.showDocuments,
      showArchives: showArchives ?? this.showArchives,
      includeSubfolders: includeSubfolders ?? this.includeSubfolders,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      showDuplicatesOnly: showDuplicatesOnly ?? this.showDuplicatesOnly,
      duplicateCriteria: duplicateCriteria ?? this.duplicateCriteria,
      locations: locations ?? this.locations,
    );
  }
}
