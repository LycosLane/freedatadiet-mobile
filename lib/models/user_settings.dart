import 'package:flutter/material.dart';
import 'duplicate_rule.dart';

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

  const UserSettings({
    this.themeMode = ThemeMode.dark,
    this.barScalingMode = BarScalingMode.largestItem,
    this.showHiddenFiles = false,
    this.includeSubfolders = false,
    this.duplicateCriteria = const DuplicateMatchCriteria(),
    this.sortColumn = SortColumn.size,
    this.sortDescending = true,
    this.excludedPatterns = const ['.git', '.thumbnails', '.cache', 'Android/data'],
  });

  UserSettings copyWith({
    ThemeMode? themeMode,
    BarScalingMode? barScalingMode,
    bool? showHiddenFiles,
    bool? includeSubfolders,
    DuplicateMatchCriteria? duplicateCriteria,
    SortColumn? sortColumn,
    bool? sortDescending,
    List<String>? excludedPatterns,
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
    );
  }
}
