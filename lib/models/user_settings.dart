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

enum SortByField {
  size('Size'),
  name('Name');

  final String label;
  const SortByField(this.label);
}

class UserSettings {
  final ThemeMode themeMode;
  final BarScalingMode barScalingMode;
  final bool showHiddenFiles;
  final bool isRecursiveFlatView;
  final DuplicateMatchMode duplicateMatchMode;
  final SortByField sortBy;
  final bool sortDescending;
  final List<String> excludedPatterns;

  const UserSettings({
    this.themeMode = ThemeMode.dark,
    this.barScalingMode = BarScalingMode.largestItem,
    this.showHiddenFiles = false,
    this.isRecursiveFlatView = false,
    this.duplicateMatchMode = DuplicateMatchMode.nameAndSize,
    this.sortBy = SortByField.size,
    this.sortDescending = true,
    this.excludedPatterns = const ['.git', '.thumbnails', '.cache', 'Android/data'],
  });

  UserSettings copyWith({
    ThemeMode? themeMode,
    BarScalingMode? barScalingMode,
    bool? showHiddenFiles,
    bool? isRecursiveFlatView,
    DuplicateMatchMode? duplicateMatchMode,
    SortByField? sortBy,
    bool? sortDescending,
    List<String>? excludedPatterns,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      barScalingMode: barScalingMode ?? this.barScalingMode,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      isRecursiveFlatView: isRecursiveFlatView ?? this.isRecursiveFlatView,
      duplicateMatchMode: duplicateMatchMode ?? this.duplicateMatchMode,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
      excludedPatterns: excludedPatterns ?? this.excludedPatterns,
    );
  }
}
