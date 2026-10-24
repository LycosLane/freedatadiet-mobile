import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_settings.dart';
import '../../services/settings_service.dart';
import 'excluded_folders_section.dart';

/// Single unified bottom sheet containing:
/// 1. Custom Text / Extension search
/// 2. "What's Shown" opt-out visibility switches (Images, Videos, Audio, Documents, Archives, Subfolders, Hidden)
/// 3. Independent Duplicate Detection ("Only show duplicates" + criteria switches)
/// 4. Excluded folders (editable, with restore defaults)
/// 5. Text & UI Zoom scaling
/// 6. Appearance & Bar Scaling
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
    _filterTextController = TextEditingController(
      text: _current.customFilterText,
    );
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
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
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                const Text(
                  'Search & Extension Filter',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _filterTextController,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Filter name, .pdf, .xmp, sidecar, log...',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: theme.hintColor,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    prefixIcon: Icon(Icons.search, size: 18, color: accent),
                    suffixIcon: _current.customFilterText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _filterTextController.clear();
                              _updateSettings(
                                _current.copyWith(customFilterText: ''),
                              );
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

                // 2. "What's Shown" (Opt-out Visibility Controls - All active by default)
                _buildSectionHeader(
                  "What's Shown",
                  Icons.visibility_rounded,
                  accent,
                ),
                _buildUniformSwitch(
                  title: 'Images',
                  subtitle: 'Show .jpg, .png, .webp, .heic, .dng, .raw',
                  value: _current.showImages,
                  accent: accent,
                  onChanged: (val) =>
                      _updateSettings(_current.copyWith(showImages: val)),
                ),
                _buildUniformSwitch(
                  title: 'Videos',
                  subtitle: 'Show .mp4, .mkv, .mov, .avi, .webm, .3gp',
                  value: _current.showVideos,
                  accent: accent,
                  onChanged: (val) =>
                      _updateSettings(_current.copyWith(showVideos: val)),
                ),
                _buildUniformSwitch(
                  title: 'Audio',
                  subtitle: 'Show .mp3, .flac, .wav, .m4a, .ogg, .opus',
                  value: _current.showAudio,
                  accent: accent,
                  onChanged: (val) =>
                      _updateSettings(_current.copyWith(showAudio: val)),
                ),
                _buildUniformSwitch(
                  title: 'Documents',
                  subtitle: 'Show .pdf, .doc, .docx, .txt, .epub, .xlsx',
                  value: _current.showDocuments,
                  accent: accent,
                  onChanged: (val) =>
                      _updateSettings(_current.copyWith(showDocuments: val)),
                ),
                _buildUniformSwitch(
                  title: 'Archives & APKs',
                  subtitle: 'Show .zip, .rar, .7z, .tar, .apk, .obb',
                  value: _current.showArchives,
                  accent: accent,
                  onChanged: (val) =>
                      _updateSettings(_current.copyWith(showArchives: val)),
                ),
                _buildUniformSwitch(
                  title: 'Include subfolders',
                  subtitle:
                      'Recursively traverses and displays all nested files',
                  value: _current.includeSubfolders,
                  accent: accent,
                  onChanged: (val) => _updateSettings(
                    _current.copyWith(includeSubfolders: val),
                  ),
                ),
                _buildUniformSwitch(
                  title: 'Show hidden files',
                  subtitle: 'Includes dotfiles (.nomedia, .thumbnails, etc.)',
                  value: _current.showHiddenFiles,
                  accent: accent,
                  onChanged: (val) =>
                      _updateSettings(_current.copyWith(showHiddenFiles: val)),
                ),
                const SizedBox(height: 18),

                // 3. Duplicate Detection (Separate, Independent Section)
                _buildSectionHeader(
                  'Duplicate Detection',
                  Icons.copy_all_rounded,
                  accent,
                ),
                _buildUniformSwitch(
                  title: 'Only show duplicates',
                  subtitle:
                      'Hides unique files and surfaces duplicate copies only',
                  value: _current.showDuplicatesOnly,
                  accent: AppColors.accentAmber,
                  onChanged: (val) => _updateSettings(
                    _current.copyWith(showDuplicatesOnly: val),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                  child: Text(
                    'Duplicate Matching Criteria:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.hintColor,
                    ),
                  ),
                ),
                _buildUniformSwitch(
                  title: 'Match same file size',
                  subtitle:
                      'Matches byte size (catches identical renamed files)',
                  value: _current.duplicateCriteria.matchSize,
                  accent: accent,
                  onChanged: (val) {
                    _updateSettings(
                      _current.copyWith(
                        duplicateCriteria: _current.duplicateCriteria.copyWith(
                          matchSize: val,
                        ),
                      ),
                    );
                  },
                ),
                _buildUniformSwitch(
                  title: 'Match same file name',
                  subtitle: 'Considers filename when identifying duplicates',
                  value: _current.duplicateCriteria.matchName,
                  accent: accent,
                  onChanged: (val) {
                    _updateSettings(
                      _current.copyWith(
                        duplicateCriteria: _current.duplicateCriteria.copyWith(
                          matchName: val,
                        ),
                      ),
                    );
                  },
                ),
                _buildUniformSwitch(
                  title: 'Match same modification timestamp',
                  subtitle: 'Matches exact timestamp (useful for photo and backup syncs)',
                  value: _current.duplicateCriteria.matchTimestamp,
                  accent: accent,
                  onChanged: (val) {
                    _updateSettings(
                      _current.copyWith(
                        duplicateCriteria: _current.duplicateCriteria.copyWith(
                          matchTimestamp: val,
                        ),
                      ),
                    );
                  },
                ),
                _buildUniformSwitch(
                  title: 'Verify bit-exact hash (SHA-256)',
                  subtitle: 'Performs two-pass hash check on candidates (100% collision-proof)',
                  value: _current.duplicateCriteria.verifyHash,
                  accent: accent,
                  onChanged: (val) {
                    _updateSettings(
                      _current.copyWith(
                        duplicateCriteria: _current.duplicateCriteria.copyWith(
                          verifyHash: val,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // 4. Excluded folders (sensible defaults, editable, restorable)
                _buildSectionHeader(
                  'Excluded Folders',
                  Icons.folder_off_rounded,
                  accent,
                ),
                ExcludedFoldersSection(
                  patterns: _current.excludedPatterns,
                  accent: accent,
                  onChanged: (list) => _updateSettings(
                    _current.copyWith(excludedPatterns: list),
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Text & UI Zoom Scaling
                _buildSectionHeader(
                  'Text & UI Zoom',
                  Icons.zoom_in_rounded,
                  accent,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
                          const Text(
                            'Font & Layout Scale',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                              size: 22,
                            ),
                            onPressed: _current.textScale > 0.8
                                ? () => _updateSettings(
                                    _current.copyWith(
                                      textScale: (_current.textScale - 0.05)
                                          .clamp(0.8, 1.6),
                                    ),
                                  )
                                : null,
                          ),
                          Expanded(
                            child: Slider(
                              value: _current.textScale,
                              min: 0.8,
                              max: 1.6,
                              divisions: 16,
                              activeColor: accent,
                              onChanged: (val) => _updateSettings(
                                _current.copyWith(textScale: val),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 22,
                            ),
                            onPressed: _current.textScale < 1.6
                                ? () => _updateSettings(
                                    _current.copyWith(
                                      textScale: (_current.textScale + 0.05)
                                          .clamp(0.8, 1.6),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const Text(
                        'Tip: You can also pinch-to-zoom directly on the file list table!',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 6. Appearance & Theme
                _buildSectionHeader(
                  'Appearance & Bar Scaling',
                  Icons.palette_rounded,
                  accent,
                ),
                const Text(
                  'Theme Mode',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Bright'),
                      icon: Icon(Icons.light_mode_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('Auto'),
                      icon: Icon(Icons.brightness_auto_outlined, size: 16),
                    ),
                  ],
                  selected: {_current.themeMode},
                  onSelectionChanged: (set) =>
                      _updateSettings(_current.copyWith(themeMode: set.first)),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Usage Bar Scaling',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                RadioGroup<BarScalingMode>(
                  groupValue: _current.barScalingMode,
                  onChanged: (val) {
                    if (val != null) {
                      _updateSettings(_current.copyWith(barScalingMode: val));
                    }
                  },
                  child: Column(
                    children: BarScalingMode.values.map((mode) {
                      return RadioListTile<BarScalingMode>(
                        title: Text(
                          mode.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          mode.description,
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: mode,
                        dense: true,
                        activeColor: accent,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Reset Settings to Defaults
                _buildSectionHeader(
                  'Maintenance & Reset',
                  Icons.settings_backup_restore_rounded,
                  AppColors.accentAmber,
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: _showResetConfirmation,
                  icon: const Icon(
                    Icons.restart_alt_rounded,
                    color: AppColors.accentRose,
                  ),
                  label: const Text(
                    'Reset All Settings to Factory Defaults',
                    style: TextStyle(
                      color: AppColors.accentRose,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.accentRose.withValues(alpha: 0.5),
                    ),
                    minimumSize: const Size.fromHeight(44),
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

  Future<void> _showResetConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.accentRose),
            SizedBox(width: 8),
            Text('Reset Settings?'),
          ],
        ),
        content: const Text(
          'This will restore all filter toggles, theme, sorting, and default excluded folders to their initial factory settings.\n\nYour actual files and storage are not modified.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentRose),
            child: const Text('Reset Defaults'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final defaults = await SettingsService.resetToDefaults();
      _updateSettings(defaults);
      _filterTextController.text = defaults.customFilterText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All settings restored to factory defaults.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: accent),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
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
          color: value
              ? accent.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor,
          width: value ? 1.2 : 0.8,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
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
