import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/storage_volume.dart';
import '../models/user_settings.dart';
import '../services/platform_bridge_service.dart';
import '../services/settings_service.dart';
import 'app_diet_view.dart';
import 'disk_browser_view.dart';
import 'widgets/unified_menu_sheet.dart';

/// A location item presented in the top bar scan sources dropdown.
class LocationItem {
  final String id;
  final String label;
  final IconData icon;
  final String path;
  final bool isAppsDiet;
  final bool isVolume;
  final bool isFavorite;

  const LocationItem({
    required this.id,
    required this.label,
    required this.icon,
    this.path = '',
    this.isAppsDiet = false,
    this.isVolume = false,
    this.isFavorite = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Main application screen with scan location selector, unified filter menu, and content views.
class MainScreen extends StatefulWidget {
  final UserSettings settings;
  final ValueChanged<UserSettings> onSettingsChanged;

  const MainScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _selectedLocationId = 'internal';
  List<StorageVolume> _volumes = [];
  bool _hasStoragePermission = true;
  bool _hasUsageStatsPermission = true;

  bool _isSelectionMode = false;
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndVolumes();
  }

  Future<void> _checkPermissionsAndVolumes() async {
    final permissions = await PlatformBridgeService.checkPermissions();
    final volumes = await PlatformBridgeService.getStorageVolumes();

    if (mounted) {
      setState(() {
        _hasStoragePermission = permissions['hasStoragePermission'] ?? true;
        _hasUsageStatsPermission = permissions['hasUsageStatsPermission'] ?? true;
        _volumes = volumes;

        // If a default startup folder is configured, find matching location
        final startup = widget.settings.defaultStartupPath;
        if (startup.isNotEmpty && startup != '/storage/emulated/0') {
          final favMatch = widget.settings.favoriteFolders.where((f) => f.path == startup).firstOrNull;
          if (favMatch != null) {
            _selectedLocationId = 'fav_${favMatch.path}';
          }
        }
      });
    }
  }

  List<LocationItem> _buildAvailableLocations() {
    final primaryVolume = _volumes.where((v) => v.isPrimary).firstOrNull ?? _volumes.firstOrNull;
    final externalVolumes = _volumes.where((v) => !v.isPrimary).toList();

    final list = <LocationItem>[
      // 1. Storage Volumes
      LocationItem(
        id: 'internal',
        label: 'Internal Storage',
        icon: Icons.phone_android_rounded,
        path: primaryVolume?.path ?? '/storage/emulated/0',
        isVolume: true,
      ),
    ];

    for (final ext in externalVolumes) {
      list.add(LocationItem(
        id: 'sd_${ext.path}',
        label: ext.description.isNotEmpty ? ext.description : 'External (${ext.path.split('/').last})',
        icon: Icons.sd_card_rounded,
        path: ext.path,
        isVolume: true,
      ));
    }

    if (externalVolumes.isNotEmpty) {
      list.add(const LocationItem(
        id: 'all_storages',
        label: 'All Storages (Merged)',
        icon: Icons.storage_rounded,
        path: '',
        isVolume: true,
      ));
    }

    // 2. Favorite Folders & Quick Access
    for (final fav in widget.settings.favoriteFolders) {
      final isStartup = widget.settings.defaultStartupPath == fav.path;
      final IconData favIcon;
      final nameLower = fav.name.toLowerCase();
      if (nameLower.contains('download')) {
        favIcon = Icons.download_rounded;
      } else if (nameLower.contains('document')) {
        favIcon = Icons.description_rounded;
      } else if (nameLower.contains('dcim') || nameLower.contains('camera')) {
        favIcon = Icons.photo_camera_rounded;
      } else {
        favIcon = Icons.folder_special_rounded;
      }

      list.add(LocationItem(
        id: 'fav_${fav.path}',
        label: '${fav.name}${isStartup ? " ★" : ""}',
        icon: favIcon,
        path: fav.path,
        isFavorite: true,
      ));
    }

    // 3. Apps & Cache Diet View
    list.add(const LocationItem(
      id: 'apps_diet',
      label: 'Apps & Cache Diet',
      icon: Icons.apps_rounded,
      isAppsDiet: true,
    ));

    return list;
  }

  List<String> get _activeRootPaths {
    final locations = _buildAvailableLocations();
    final current = locations.where((l) => l.id == _selectedLocationId).firstOrNull ?? locations.first;

    if (current.id == 'all_storages') {
      return _volumes.map((v) => v.path).toList();
    }
    if (current.path.isNotEmpty) {
      return [current.path];
    }
    return ['/storage/emulated/0'];
  }

  void _openUnifiedMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UnifiedMenuSheet(
        settings: widget.settings,
        onSettingsChanged: (updated) {
          widget.onSettingsChanged(updated);
          SettingsService.saveSettings(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locations = _buildAvailableLocations();

    final currentLoc = locations.where((l) => l.id == _selectedLocationId).firstOrNull ?? locations.first;
    final isAppsDiet = currentLoc.isAppsDiet;

    final hasActiveFilters = widget.settings.hasActiveTypeFilters ||
        widget.settings.showDuplicatesOnly ||
        widget.settings.customFilterText.trim().isNotEmpty ||
        widget.settings.includeSubfolders;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: _buildLocationDropdown(locations, currentLoc),
        actions: [
          if (!isAppsDiet) ...[
            // Select for Deletion Mode (Edit mode toggle)
            IconButton(
              icon: Icon(
                _isSelectionMode ? Icons.close_rounded : Icons.checklist_rounded,
                color: _isSelectionMode ? theme.colorScheme.primary : null,
              ),
              tooltip: _isSelectionMode ? 'Cancel selection (exit edit mode)' : 'Select for deletion',
              onPressed: () => setState(() => _isSelectionMode = !_isSelectionMode),
            ),
          ],
          // Unified Filters & Preferences Menu Button
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Filters & Preferences',
                onPressed: _openUnifiedMenu,
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Storage Access Banner (MANAGE_EXTERNAL_STORAGE)
          if (!_hasStoragePermission)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppColors.accentRose.withValues(alpha: 0.18),
              child: Row(
                children: [
                  const Icon(Icons.folder_special_rounded, color: AppColors.accentRose, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'All Files Access is required to scan disk space & find large files.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await PlatformBridgeService.requestStoragePermission();
                      await _checkPermissionsAndVolumes();
                    },
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.accentRose,
                    ),
                    child: const Text('Grant Access', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),

          // Main View Content
          Expanded(
            child: isAppsDiet
                ? AppDietView(
                    hasUsageStatsPermission: _hasUsageStatsPermission,
                    onRequestPermission: () async {
                      await PlatformBridgeService.requestUsageStatsPermission();
                      await _checkPermissionsAndVolumes();
                    },
                  )
                : DiskBrowserView(
                    key: ValueKey('${currentLoc.id}_$_refreshCounter'),
                    rootPaths: _activeRootPaths,
                    settings: widget.settings,
                    onSettingsChanged: widget.onSettingsChanged,
                    searchQuery: '',
                    isSelectionMode: _isSelectionMode,
                    onSelectionModeChanged: (mode) => setState(() => _isSelectionMode = mode),
                    onRescanRequested: () => setState(() => _refreshCounter++),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDropdown(List<LocationItem> locations, LocationItem currentLoc) {
    final theme = Theme.of(context);

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: currentLoc.id,
        isDense: true,
        borderRadius: BorderRadius.circular(8),
        selectedItemBuilder: (context) {
          return locations.map((loc) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(loc.icon, size: 19, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: Text(
                    loc.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }).toList();
        },
        items: locations.map((loc) {
          return DropdownMenuItem<String>(
            value: loc.id,
            child: Row(
              children: [
                Icon(
                  loc.icon,
                  size: 18,
                  color: loc.isFavorite
                      ? AppColors.accentAmber
                      : (loc.isAppsDiet ? theme.colorScheme.secondary : null),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: loc.id == currentLoc.id ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (newId) {
          if (newId != null && newId != _selectedLocationId) {
            setState(() {
              _selectedLocationId = newId;
              _isSelectionMode = false;
            });
          }
        },
      ),
    );
  }
}
