import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_settings.dart';

/// Single unified, clean bottom sheet containing all search filters, type filters,
/// duplicate criteria, zoom scaling, favorites, and settings with consistent accent styling.
class UnifiedMenuSheet extends StatefulWidget {
  final UserSettings settings;
  final ValueChanged<UserSettings> onSettingsChanged;

  const UnifiedMenuSheet({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<UnifiedMenuSheet> createState() => _UnifiedMenuSheetState();
}

class _UnifiedMenuSheetState extends State<UnifiedMenuSheet> {
  late TextEditingController _filterTextController;
  late UserSettings _current;

  @override
  void initState() {
    super.initState();
    _current = widget.settings;
    _filterTextController = TextEditingController(text: _current.customFilterText);
  }

  @override
  void dispose() {
    _filterTextController.dispose();
    super.dispose();
  }

  void _updateSettings(UserSettings updated) {
    setState(() => _current = updated);
    widget.onSettingsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 22, color: accent),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Filters & Preferences',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Scrollable Settings Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Custom Text / Extension Filter Input
                const Text('Search & Extension Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _filterTextController,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Filter name, .pdf, .xmp, sidecar, log...',
                    hintStyle: TextStyle(fontSize: 12.5, color: theme.hintColor),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    prefixIcon: Icon(Icons.search, size: 18, color: accent),
                    suffixIcon: _current.customFilterText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _filterTextController.clear();
                              _updateSettings(_current.copyWith(customFilterText: ''));
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    _updateSettings(_current.copyWith(customFilterText: val));
                  },
                ),
                const SizedBox(height: 18),

                // 2. File Type Toggles (Uniform Switch Style)
                _buildSectionHeader('Filter by File Type', Icons.category_rounded, accent),
                _buildUniformSwitch(
                  title: 'Images',
                  subtitle: '.jpg, .png, .webp, .heic, .dng, .raw',
                  value: _current.filterImages,
                  accent: accent,
                  onChanged: (val) => _updateSettings(_current.copyWith(filterImages: val)),
                ),
                _buildUniformSwitch(
                  title: 'Videos',
                  subtitle: '.mp4, .mkv, .mov, .avi, .webm, .3gp',
                  value: _current.filterVideos,
                  accent: accent,
                  onChanged: (val) => _updateSettings(_current.copyWith(filterVideos: val)),
                ),
                _buildUniformSwitch(
                  title: 'Audio',
                  subtitle: '.mp3, .flac, .wav, .m4a, .ogg, .opus',
                  value: _current.filterAudio,
                  accent: accent,
                  onChanged: (val) => _updateSettings(_current.copyWith(filterAudio: val)),
                ),
                _buildUniformSwitch(
                  title: 'Documents',
                  subtitle: '.pdf, .doc, .docx, .txt, .epub, .xlsx',
                  value: _current.filterDocuments,
                  accent: accent,
                  onChanged: (val) => _updateSettings(_current.copyWith(filterDocuments: val)),
                ),
                _buildUniformSwitch(
                  title: 'Archives & APKs',
                  subtitle: '.zip, .rar, .7z, .tar, .apk, .obb',
                  value: _current.filterArchives,
                  accent: accent,
                  onChanged: (val) => _updateSettings(_current.copyWith(filterArchives: val)),
                ),
                const SizedBox(height: 18),

                // 3. Scope & Visibility (Uniform Switch Style)
                _buildSectionHeader('Scope & Visibility', Icons.visibility_rounded, accent),
                _buildUniformSwitch(
                  title: 'Include subfolders',
                  subtitle: 'Traverses through all subdirectories and shows files in current level',
                  value: _current.includeSubfolders,
                  accent: accent,
                  onChanged: (val) => _updateSettings(_current.copyWith(includeSubfolders: val)),
                ),
                _buildUniformSwitch(
                  title: 'Show duplicates only',
                  subtitle: 'Filters list to only display files matching duplicate criteria',
                  value: _current.showDuplicatesOnly,
                  accent: AppColors.accentAmber,
                  onChanged: (val) => _updateSettings(_current.copyWith(showDuplicatesOnly: val)),
                ),
                _buildUniformSwitch(
                  title: 'Show hidden files',
                  subtitle: 'Includes dotfiles (.nomedia, .thumbnails, etc.)',
                  value: _current.showHiddenFiles,
                  accent: accent,
                  onChanged: (val) => _updateSettings(_current.copyWith(showHiddenFiles: val)),
                ),
                const SizedBox(height: 18),

                // 4. Duplicate Matching Criteria (Uniform Switch Style)
                _buildSectionHeader('Duplicate Detection Rules', Icons.copy_all_rounded, accent),
                _buildUniformSwitch(
                  title: 'Match same file size',
                  subtitle: 'Considers byte size when identifying duplicates',
                  value: _current.duplicateCriteria.matchSize,
                  accent: accent,
                  onChanged: (val) {
                    _updateSettings(_current.copyWith(
                      duplicateCriteria: _current.duplicateCriteria.copyWith(matchSize: val),
                    ));
                  },
                ),
                _buildUniformSwitch(
                  title: 'Match same file name',
                  subtitle: 'Considers filename when identifying duplicates',
                  value: _current.duplicateCriteria.matchName,
                  accent: accent,
                  onChanged: (val) {
                    _updateSettings(_current.copyWith(
                      duplicateCriteria: _current.duplicateCriteria.copyWith(matchName: val),
                    ));
                  },
                ),
                _buildUniformSwitch(
                  title: 'Match same modification timestamp',
                  subtitle: 'Matches exact timestamp (useful for camera syncs)',
                  value: _current.duplicateCriteria.matchTimestamp,
                  accent: accent,
                  onChanged: (val) {
                    _updateSettings(_current.copyWith(
                      duplicateCriteria: _current.duplicateCriteria.copyWith(matchTimestamp: val),
                    ));
                  },
                ),
                const SizedBox(height: 18),

                // 5. Text & UI Zoom Scaling
                _buildSectionHeader('Text & UI Zoom', Icons.zoom_in_rounded, accent),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Font & Layout Scale', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(
                            '${(_current.textScale * 100).round()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: accent,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                            onPressed: _current.textScale > 0.8
                                ? () => _updateSettings(_current.copyWith(textScale: (_current.textScale - 0.05).clamp(0.8, 1.6)))
                                : null,
                          ),
                          Expanded(
                            child: Slider(
                              value: _current.textScale,
                              min: 0.8,
                              max: 1.6,
                              divisions: 16,
                              activeColor: accent,
                              onChanged: (val) => _updateSettings(_current.copyWith(textScale: val)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                            onPressed: _current.textScale < 1.6
                                ? () => _updateSettings(_current.copyWith(textScale: (_current.textScale + 0.05).clamp(0.8, 1.6)))
                                : null,
                          ),
                        ],
                      ),
                      const Text(
                        'Tip: You can also pinch-to-zoom directly on the file list table!',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 6. Favorites & Startup Folder
                _buildSectionHeader('Favorite Folders & Startup', Icons.folder_special_rounded, accent),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      ..._current.favoriteFolders.map((fav) {
                        final isStartup = _current.defaultStartupPath == fav.path;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isStartup ? Icons.star_rounded : Icons.star_border_rounded,
                            color: isStartup ? AppColors.accentAmber : theme.hintColor,
                            size: 22,
                          ),
                          title: Text(fav.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${fav.path}${isStartup ? " (Default Startup)" : ""}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isStartup ? accent : theme.hintColor,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isStartup ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: isStartup ? accent : theme.hintColor,
                                ),
                                tooltip: 'Set as Startup Folder',
                                onPressed: () {
                                  _updateSettings(_current.copyWith(defaultStartupPath: fav.path));
                                },
                              ),
                              if (!const ['Downloads', 'Documents', 'Camera (DCIM)'].contains(fav.name))
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  tooltip: 'Remove Bookmark',
                                  onPressed: () {
                                    final updatedFavs = _current.favoriteFolders.where((f) => f.path != fav.path).toList();
                                    _updateSettings(_current.copyWith(favoriteFolders: updatedFavs));
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 7. Appearance & Theme
                _buildSectionHeader('Appearance & Bar Scaling', Icons.palette_rounded, accent),
                const Text('Theme Mode', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined, size: 16)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Bright'), icon: Icon(Icons.light_mode_outlined, size: 16)),
                    ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto_outlined, size: 16)),
                  ],
                  selected: {_current.themeMode},
                  onSelectionChanged: (set) => _updateSettings(_current.copyWith(themeMode: set.first)),
                ),
                const SizedBox(height: 14),

                const Text('Usage Bar Scaling', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                RadioGroup<BarScalingMode>(
                  groupValue: _current.barScalingMode,
                  onChanged: (val) {
                    if (val != null) _updateSettings(_current.copyWith(barScalingMode: val));
                  },
                  child: Column(
                    children: BarScalingMode.values.map((mode) {
                      return RadioListTile<BarScalingMode>(
                        title: Text(mode.label, style: const TextStyle(fontSize: 13)),
                        subtitle: Text(mode.description, style: const TextStyle(fontSize: 11)),
                        value: mode,
                        dense: true,
                        activeColor: accent,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: accent),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUniformSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required Color accent,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? accent.withValues(alpha: 0.5) : Theme.of(context).dividerColor,
          width: value ? 1.2 : 0.8,
        ),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        value: value,
        activeThumbColor: accent,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        onChanged: onChanged,
      ),
    );
  }
}
