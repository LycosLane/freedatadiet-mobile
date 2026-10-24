import 'package:flutter/material.dart';
import 'duplicate_rule.dart';
import 'favorite_folder.dart';

enum BarScalingMode {
  largestItem('Largest Item in View', 'Bars scale relative to the largest item visible.'),
  folderTotal('Current Folder Total', 'Bars scale relative to the total size of the current folder.'),
  driveTotal('Total Disk Capacity', 'Bars scale relative to the entire storage volume.');

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
  final ThemeMode themeMode;
  final BarScalingMode barScalingMode;
  final bool showHiddenFiles;
  final bool includeSubfolders;
  final DuplicateMatchCriteria duplicateCriteria;
  final SortColumn sortColumn;
  final bool sortDescending;
  final List<String> excludedPatterns;

  // Zoom / Font Scale
  final double textScale; // e.g. 0.8 to 1.6

  // Unified Filter Options
  final String customFilterText;
  final bool filterImages;
  final bool filterVideos;
  final bool filterAudio;
  final bool filterDocuments;
  final bool filterArchives;
  final bool showDuplicatesOnly;

  // Folder Bookmarks & Startup Path
  final List<FavoriteFolder> favoriteFolders;
  final String defaultStartupPath;

  const UserSettings({
    this.themeMode = ThemeMode.dark,
    this.barScalingMode = BarScalingMode.largestItem,
    this.showHiddenFiles = false,
    this.includeSubfolders = false,
    this.duplicateCriteria = const DuplicateMatchCriteria(),
    this.sortColumn = SortColumn.size,
    this.sortDescending = true,
    this.excludedPatterns = const ['.git', '.thumbnails', '.cache', 'Android/data'],
    this.textScale = 1.0,
    this.customFilterText = '',
    this.filterImages = false,
    this.filterVideos = false,
    this.filterAudio = false,
    this.filterDocuments = false,
    this.filterArchives = false,
    this.showDuplicatesOnly = false,
    this.favoriteFolders = const [
      FavoriteFolder(name: 'Downloads', path: '/storage/emulated/0/Download'),
      FavoriteFolder(name: 'Documents', path: '/storage/emulated/0/Documents'),
      FavoriteFolder(name: 'Camera (DCIM)', path: '/storage/emulated/0/DCIM'),
    ],
    this.defaultStartupPath = '/storage/emulated/0',
  });

  bool get hasActiveTypeFilters =>
      filterImages || filterVideos || filterAudio || filterDocuments || filterArchives;

  UserSettings copyWith({
    ThemeMode? themeMode,
    BarScalingMode? barScalingMode,
    bool? showHiddenFiles,
    bool? includeSubfolders,
    DuplicateMatchCriteria? duplicateCriteria,
    SortColumn? sortColumn,
    bool? sortDescending,
    List<String>? excludedPatterns,
    double? textScale,
    String? customFilterText,
    bool? filterImages,
    bool? filterVideos,
    bool? filterAudio,
    bool? filterDocuments,
    bool? filterArchives,
    bool? showDuplicatesOnly,
    List<FavoriteFolder>? favoriteFolders,
    String? defaultStartupPath,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      barScalingMode: barScalingMode ?? this.barScalingMode,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      includeSubfolders: includeSubfolders ?? this.includeSubfolders,
      duplicateCriteria: duplicateCriteria ?? this.duplicateCriteria,
      sortColumn: sortColumn ?? this.sortColumn,
      sortDescending: sortDescending ?? this.sortDescending,
      excludedPatterns: excludedPatterns ?? this.excludedPatterns,
      textScale: textScale ?? this.textScale,
      customFilterText: customFilterText ?? this.customFilterText,
      filterImages: filterImages ?? this.filterImages,
      filterVideos: filterVideos ?? this.filterVideos,
      filterAudio: filterAudio ?? this.filterAudio,
      filterDocuments: filterDocuments ?? this.filterDocuments,
      filterArchives: filterArchives ?? this.filterArchives,
      showDuplicatesOnly: showDuplicatesOnly ?? this.showDuplicatesOnly,
      favoriteFolders: favoriteFolders ?? this.favoriteFolders,
      defaultStartupPath: defaultStartupPath ?? this.defaultStartupPath,
    );
  }
}
