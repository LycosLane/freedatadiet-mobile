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
  late DuplicateMatchMode _duplicateMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.settings.themeMode;
    _barScaling = widget.settings.barScalingMode;
    _showHidden = widget.settings.showHiddenFiles;
    _duplicateMode = widget.settings.duplicateMatchMode;
  }

  void _updateAndNotify() {
    final updated = widget.settings.copyWith(
      themeMode: _themeMode,
      barScalingMode: _barScaling,
      showHiddenFiles: _showHidden,
      duplicateMatchMode: _duplicateMode,
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
              const SizedBox(height: 12),

              // Duplicate Detection Matching Criteria
              const Text('Duplicate Detection Criteria', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              RadioGroup<DuplicateMatchMode>(
                groupValue: _duplicateMode,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _duplicateMode = val);
                    _updateAndNotify();
                  }
                },
                child: Column(
                  children: DuplicateMatchMode.values.map((mode) {
                    return RadioListTile<DuplicateMatchMode>(
                      title: Text(mode.label, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(mode.description, style: const TextStyle(fontSize: 11)),
                      value: mode,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Hidden Files Toggle
              SwitchListTile(
                title: const Text('Show Hidden Files', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Includes dotfiles (.nomedia, .thumbnails, etc.)', style: TextStyle(fontSize: 11)),
                value: _showHidden,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showHidden = val);
                  _updateAndNotify();
                },
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
