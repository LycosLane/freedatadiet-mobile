import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/saved_location.dart';

/// Interactive modal sheet allowing users to select and reorder scan locations and favorites.
/// The item at index 0 is the default startup entry point.
class LocationReorderSheet extends StatefulWidget {
  final List<SavedLocation> locations;
  final String selectedLocationId;
  final ValueChanged<SavedLocation> onSelectLocation;
  final ValueChanged<List<SavedLocation>> onReorder;
  final ValueChanged<SavedLocation> onRemoveLocation;

  const LocationReorderSheet({
    super.key,
    required this.locations,
    required this.selectedLocationId,
    required this.onSelectLocation,
    required this.onReorder,
    required this.onRemoveLocation,
  });

  @override
  State<LocationReorderSheet> createState() => _LocationReorderSheetState();
}

class _LocationReorderSheetState extends State<LocationReorderSheet> {
  late List<SavedLocation> _items;

  @override
  void initState() {
    super.initState();
    _items = List<SavedLocation>.from(widget.locations);
  }

  bool _isAvailable(SavedLocation loc) {
    if (loc.isAppsDiet) return true;
    if (loc.path.isEmpty) return false;
    try {
      return Directory(loc.path).existsSync();
    } catch (_) {
      return false;
    }
  }

  IconData _iconForLocation(SavedLocation loc) {
    if (loc.isAppsDiet) return Icons.apps_rounded;
    if (loc.isInternal) return Icons.phone_android_rounded;
    if (loc.isExternal) return Icons.sd_card_rounded;

    final nameLower = loc.name.toLowerCase();
    if (nameLower.contains('download')) return Icons.download_rounded;
    if (nameLower.contains('document')) return Icons.description_rounded;
    if (nameLower.contains('dcim') || nameLower.contains('camera')) return Icons.photo_camera_rounded;
    return Icons.folder_special_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_shared_rounded, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Locations & Favorites',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Long press & drag to reorder • Top item is startup folder',
                        style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),

          // Reorderable Locations List
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                });
                widget.onReorder(_items);
              },
              itemBuilder: (context, index) {
                final loc = _items[index];
                final available = _isAvailable(loc);
                final isSelected = loc.id == widget.selectedLocationId;
                final isStartup = index == 0;
                final icon = _iconForLocation(loc);

                return Material(
                  key: ValueKey(loc.id),
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Icon(
                      icon,
                      color: !available
                          ? theme.disabledColor
                          : (isSelected
                              ? accent
                              : (loc.isFavorite ? AppColors.accentAmber : theme.colorScheme.onSurface)),
                      size: 22,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            loc.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: !available ? theme.disabledColor : null,
                            ),
                          ),
                        ),
                        if (isStartup) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: accent.withValues(alpha: 0.5), width: 0.8),
                            ),
                            child: Text(
                              '★ Startup',
                              style: TextStyle(
                                color: accent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (!available) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.accentRose.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.5), width: 0.8),
                            ),
                            child: const Text(
                              'Not available',
                              style: TextStyle(
                                color: AppColors.accentRose,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      !available
                          ? 'Storage disconnected or path inaccessible'
                          : (loc.path.isNotEmpty ? loc.path : 'App footprint & cache'),
                      style: TextStyle(
                        fontSize: 11,
                        color: !available ? AppColors.accentRose.withValues(alpha: 0.7) : theme.hintColor,
                        fontFamily: loc.path.isNotEmpty ? 'monospace' : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loc.isFavorite)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                            tooltip: 'Remove from favorites',
                            onPressed: () {
                              setState(() {
                                _items.removeWhere((i) => i.id == loc.id);
                              });
                              widget.onRemoveLocation(loc);
                            },
                          ),
                        const Icon(Icons.drag_handle_rounded, size: 20),
                      ],
                    ),
                    onTap: () {
                      if (!available) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Location "${loc.name}" is currently not accessible.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      widget.onSelectLocation(loc);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
