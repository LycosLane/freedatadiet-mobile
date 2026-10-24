import 'package:flutter/material.dart';
import '../models/duplicate_rule.dart';
import '../models/user_settings.dart';

/// Modal dialog for modifying persistent FreeDataDiet settings.
class SettingsDialog extends StatefulWidget {
  final UserSettings settings;
  final ValueChanged<UserSettings> onSettingsChanged;

  const SettingsDialog({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late ThemeMode _themeMode;
  late BarScalingMode _barScaling;
  late bool _showHidden;
  late bool _includeSubfolders;
  late DuplicateMatchCriteria _duplicateCriteria;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.settings.themeMode;
    _barScaling = widget.settings.barScalingMode;
    _showHidden = widget.settings.showHiddenFiles;
    _includeSubfolders = widget.settings.includeSubfolders;
    _duplicateCriteria = widget.settings.duplicateCriteria;
  }

  void _updateAndNotify() {
    final updated = widget.settings.copyWith(
      themeMode: _themeMode,
      barScalingMode: _barScaling,
      showHiddenFiles: _showHidden,
      includeSubfolders: _includeSubfolders,
      duplicateCriteria: _duplicateCriteria,
    );
    widget.onSettingsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.settings_outlined, size: 22),
          SizedBox(width: 8),
          Text('Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Theme Selection (Dark, Bright/Light, System)
              const Text('Theme Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined, size: 16)),
                  ButtonSegment(value: ThemeMode.light, label: Text('Bright'), icon: Icon(Icons.light_mode_outlined, size: 16)),
                  ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto_outlined, size: 16)),
                ],
                selected: {_themeMode},
                onSelectionChanged: (set) {
                  setState(() => _themeMode = set.first);
                  _updateAndNotify();
                },
              ),
              const SizedBox(height: 16),

              // View Options: Include subfolders & Show hidden files
              const Text('View & Scope Options', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SwitchListTile(
                title: const Text('Include subfolders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: const Text('Scans through all subdirectories and shows files in current level', style: TextStyle(fontSize: 11)),
                value: _includeSubfolders,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _includeSubfolders = val);
                  _updateAndNotify();
                },
              ),
              SwitchListTile(
                title: const Text('Show hidden files', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: const Text('Includes dotfiles (.nomedia, .thumbnails, etc.)', style: TextStyle(fontSize: 11)),
                value: _showHidden,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showHidden = val);
                  _updateAndNotify();
                },
              ),
              const SizedBox(height: 12),

              // Duplicate Detection Criteria (Independent Checkboxes)
              const Text('Duplicate Detection Criteria', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text(
                'Select which criteria must match to flag files as duplicates:',
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                title: const Text('Same file size', style: TextStyle(fontSize: 13)),
                value: _duplicateCriteria.matchSize,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) {
                  setState(() {
                    _duplicateCriteria = _duplicateCriteria.copyWith(matchSize: val ?? false);
                  });
                  _updateAndNotify();
                },
              ),
              CheckboxListTile(
                title: const Text('Same file name', style: TextStyle(fontSize: 13)),
                value: _duplicateCriteria.matchName,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) {
                  setState(() {
                    _duplicateCriteria = _duplicateCriteria.copyWith(matchName: val ?? false);
                  });
                  _updateAndNotify();
                },
              ),
              CheckboxListTile(
                title: const Text('Same modification timestamp', style: TextStyle(fontSize: 13)),
                value: _duplicateCriteria.matchTimestamp,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) {
                  setState(() {
                    _duplicateCriteria = _duplicateCriteria.copyWith(matchTimestamp: val ?? false);
                  });
                  _updateAndNotify();
                },
              ),
              const SizedBox(height: 12),

              // Usage Bar Scaling Mode
              const Text('Usage Bar Scaling', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              RadioGroup<BarScalingMode>(
                groupValue: _barScaling,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _barScaling = val);
                    _updateAndNotify();
                  }
                },
                child: Column(
                  children: BarScalingMode.values.map((mode) {
                    return RadioListTile<BarScalingMode>(
                      title: Text(mode.label, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(mode.description, style: const TextStyle(fontSize: 11)),
                      value: mode,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
