import 'package:flutter/material.dart';

import '../../core/utils/path_rules.dart';
import '../../models/user_settings.dart';

/// Editable list of folders that scans skip. Defaults are sensible for most people,
/// power users can add their own, and "Restore defaults" brings everything back.
class ExcludedFoldersSection extends StatefulWidget {
  final List<String> patterns;
  final Color accent;
  final ValueChanged<List<String>> onChanged;

  const ExcludedFoldersSection({
    super.key,
    required this.patterns,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<ExcludedFoldersSection> createState() => _ExcludedFoldersSectionState();
}

class _ExcludedFoldersSectionState extends State<ExcludedFoldersSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDefault {
    final a = widget.patterns.map((e) => e.toLowerCase()).toSet();
    final b = UserSettings.defaultExcludedPatterns
        .map((e) => e.toLowerCase())
        .toSet();
    return a.length == b.length && a.containsAll(b);
  }

  void _add() {
    final value = PathRules.normalizePattern(_controller.text);
    if (value.isEmpty) return;
    final exists = widget.patterns.any(
      (p) => p.toLowerCase() == value.toLowerCase(),
    );
    if (!exists) widget.onChanged([...widget.patterns, value]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'These folders are skipped when scanning and measuring sizes. A name matches a whole folder, for example .cache or Android/data.',
            style: TextStyle(fontSize: 11.5, color: theme.hintColor),
          ),
          const SizedBox(height: 10),
          if (widget.patterns.isEmpty)
            Text(
              'Nothing is skipped.',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final p in widget.patterns)
                  InputChip(
                    label: Text(p, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    onDeleted: () => widget.onChanged(
                      widget.patterns.where((e) => e != p).toList(),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => _add(),
                  decoration: InputDecoration(
                    hintText: 'Add folder name',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: theme.hintColor,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Add',
                icon: const Icon(Icons.add_rounded),
                onPressed: _add,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: const Text('Restore defaults'),
              onPressed: _isDefault
                  ? null
                  : () => widget.onChanged(
                      List.of(UserSettings.defaultExcludedPatterns),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
