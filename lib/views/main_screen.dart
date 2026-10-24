import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/path_rules.dart';
import '../models/saved_location.dart';
import '../models/storage_volume.dart';
import '../models/user_settings.dart';
import '../services/platform_bridge_service.dart';
import '../services/settings_service.dart';
import 'app_diet_view.dart';
import 'disk_browser_view.dart';
import 'widgets/location_reorder_sheet.dart';
import 'widgets/unified_menu_sheet.dart';

/// Main application screen with interactive location switcher, unified filter menu, and content views.
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  /// How often to double check that the current storage is still there (cheap existsSync).
  static const Duration _storagePollInterval = Duration(seconds: 3);

  final GlobalKey<DiskBrowserViewState> _browserKey =
      GlobalKey<DiskBrowserViewState>();
  StreamSubscription<void>? _volumeSub;
  Timer? _volumeDebounce;
  Timer? _storagePoll;
  bool _checkingVolumes = false;

  String? _selectedLocationId;
  List<StorageVolume> _volumes = [];
  bool _hasStoragePermission = true;
  bool _hasUsageStatsPermission = true;

  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndVolumes();

    // Storage mounted or removed (SD card, USB OTG): re-read volumes shortly after the event settles.
    _volumeSub = PlatformBridgeService.volumeChanges.listen((_) {
      _volumeDebounce?.cancel();
      _volumeDebounce = Timer(
        const Duration(milliseconds: 600),
        _onVolumesChanged,
      );
    });
    // Safety net for removals that do not send a broadcast.
    _storagePoll = Timer.periodic(_storagePollInterval, (_) {
      final loc = _currentLocation;
      if (!loc.isAppsDiet &&
          loc.path.isNotEmpty &&
          !_isLocationAvailable(loc)) {
        _onVolumesChanged();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _volumeSub?.cancel();
    _volumeDebounce?.cancel();
    _storagePoll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Permissions may have been granted in system settings, and storage may have changed while away.
      _checkPermissionsAndVolumes();
      _onVolumesChanged();
    }
  }

  bool _isLocationAvailable(SavedLocation loc) {
    if (loc.isAppsDiet) return true;
    if (loc.path.isEmpty) return false;
    try {
      return Directory(loc.path).existsSync();
    } catch (_) {
      return false;
    }
  }

  List<SavedLocation> get _mergedLocations => _mergedLocationsFor(_volumes);

  List<SavedLocation> _mergedLocationsFor(List<StorageVolume> volumes) {
    final list = List<SavedLocation>.from(widget.settings.locations);

    // Merge any detected external volumes that aren't already in the list
    for (final vol in volumes) {
      if (!vol.isPrimary) {
        final existingIndex = list.indexWhere((l) => l.path == vol.path);
        if (existingIndex == -1) {
          list.add(
            SavedLocation(
              id: 'sd_${vol.path}',
              name: vol.description.isNotEmpty
                  ? vol.description
                  : 'External (${vol.path.split('/').last})',
              path: vol.path,
              type: 'external',
            ),
          );
        }
      }
    }

    return list;
  }

  Future<void> _checkPermissionsAndVolumes() async {
    final permissions = await PlatformBridgeService.checkPermissions();
    final volumes = await PlatformBridgeService.getStorageVolumes();

    if (mounted) {
      setState(() {
        _hasStoragePermission = permissions['hasStoragePermission'] ?? true;
        _hasUsageStatsPermission =
            permissions['hasUsageStatsPermission'] ?? true;
        _volumes = volumes;

        if (_selectedLocationId == null) {
          // On initial launch: select the top-most available entry in locations!
          // If the top item is not available (e.g. unplugged SD/OTG), fall back to the next available item.
          final locs = _mergedLocations;
          final availableFirst =
              locs.where((l) => _isLocationAvailable(l)).firstOrNull ??
              locs.firstOrNull;
          _selectedLocationId = availableFirst?.id ?? 'internal';
        }
      });
    }
  }

  /// Re-reads the storage volumes after a mount or removal event.
  /// If the storage we are looking at is gone, switch to the next available location and tell the user.
  /// If a volume we are inside of was (re)mounted, scan it again.
  Future<void> _onVolumesChanged() async {
    if (_checkingVolumes) return;
    _checkingVolumes = true;
    try {
      final newVolumes = await PlatformBridgeService.getStorageVolumes();
      if (!mounted) return;

      final oldPaths = _volumes.map((v) => v.path).toSet();
      final added = newVolumes
          .where((v) => !oldPaths.contains(v.path))
          .toList();

      final loc = _currentLocation;
      final locationGone =
          !loc.isAppsDiet && loc.path.isNotEmpty && !_isLocationAvailable(loc);
      final remounted =
          !loc.isAppsDiet &&
          loc.path.isNotEmpty &&
          added.any((v) => PathRules.isUnder(loc.path, v.path));

      SavedLocation? fallback;
      if (locationGone) {
        final candidates = _mergedLocationsFor(newVolumes);
        fallback = candidates
            .where((l) => l.id != loc.id && _isLocationAvailable(l))
            .firstOrNull;
      }

      setState(() {
        _volumes = newVolumes;
        if (fallback != null) {
          _selectedLocationId = fallback.id;
          _isSelectionMode = false;
        }
      });

      if (fallback != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '"${loc.name}" is no longer available. Switched to "${fallback.name}".',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
      } else if (remounted) {
        _browserKey.currentState?.rescan();
      }
    } finally {
      _checkingVolumes = false;
    }
  }

  /// Capacity of the volume that contains [path], for the "Total Disk Capacity" bar mode.
  int? _driveTotalFor(String path) {
    StorageVolume? best;
    for (final v in _volumes) {
      if (PathRules.isUnder(path, v.path) &&
          (best == null || v.path.length > best.path.length)) {
        best = v;
      }
    }
    final total = best?.totalBytes ?? 0;
    return total > 0 ? total : null;
  }

  SavedLocation get _currentLocation {
    final locs = _mergedLocations;
    return locs.where((l) => l.id == _selectedLocationId).firstOrNull ??
        locs.firstOrNull ??
        const SavedLocation(
          id: 'internal',
          name: 'Internal Storage',
          path: '/storage/emulated/0',
          type: 'internal',
        );
  }

  List<String> get _activeRootPaths {
    final loc = _currentLocation;
    if (loc.path.isNotEmpty) {
      return [loc.path];
    }
    return ['/storage/emulated/0'];
  }

  void _openLocationSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationReorderSheet(
        locations: _mergedLocations,
        selectedLocationId: _selectedLocationId ?? 'internal',
        onSelectLocation: (loc) {
          Navigator.of(context).pop();
          setState(() {
            _selectedLocationId = loc.id;
            _isSelectionMode = false;
          });
        },
        onReorder: (updatedList) {
          final updatedSettings = widget.settings.copyWith(
            locations: updatedList,
          );
          widget.onSettingsChanged(updatedSettings);
          SettingsService.saveSettings(updatedSettings);
          setState(() {});
        },
        onRemoveLocation: (loc) {
          final updatedList = widget.settings.locations
              .where((l) => l.id != loc.id)
              .toList();
          final updatedSettings = widget.settings.copyWith(
            locations: updatedList,
          );
          widget.onSettingsChanged(updatedSettings);
          SettingsService.saveSettings(updatedSettings);
          setState(() {
            if (_selectedLocationId == loc.id) {
              _selectedLocationId = updatedList.firstOrNull?.id ?? 'internal';
            }
          });
        },
      ),
    );
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

  IconData _iconForLocation(SavedLocation loc) {
    if (loc.isAppsDiet) return Icons.apps_rounded;
    if (loc.isInternal) return Icons.phone_android_rounded;
    if (loc.isExternal) return Icons.sd_card_rounded;

    final nameLower = loc.name.toLowerCase();
    if (nameLower.contains('download')) return Icons.download_rounded;
    if (nameLower.contains('document')) return Icons.description_rounded;
    if (nameLower.contains('dcim') || nameLower.contains('camera')) {
      return Icons.photo_camera_rounded;
    }
    return Icons.folder_special_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLoc = _currentLocation;
    final isAppsDiet = currentLoc.isAppsDiet;
    final hasActiveFilters = widget.settings.hasActiveFilters;

    // Back gesture: leave selection, go up a folder, and only then close the app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isSelectionMode && isAppsDiet) {
          setState(() => _isSelectionMode = false);
          return;
        }
        if (_browserKey.currentState?.handleBack() ?? false) return;
        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 12,
          title: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _openLocationSelector,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForLocation(currentLoc),
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      currentLoc.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 22,
                    color: theme.hintColor,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (!isAppsDiet) ...[
              // Select for Deletion Mode (Edit mode toggle)
              IconButton(
                icon: Icon(
                  _isSelectionMode
                      ? Icons.close_rounded
                      : Icons.checklist_rounded,
                  color: _isSelectionMode ? theme.colorScheme.primary : null,
                ),
                tooltip: _isSelectionMode
                    ? 'Cancel selection (exit edit mode)'
                    : 'Select for deletion',
                onPressed: () =>
                    setState(() => _isSelectionMode = !_isSelectionMode),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                color: AppColors.accentRose.withValues(alpha: 0.18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_special_rounded,
                      color: AppColors.accentRose,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'All Files Access is required to scan disk space & find large files.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
                      child: const Text(
                        'Grant Access',
                        style: TextStyle(fontSize: 11),
                      ),
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
                  : KeyedSubtree(
                      key: ValueKey(currentLoc.id),
                      child: DiskBrowserView(
                        key: _browserKey,
                        rootPaths: _activeRootPaths,
                        settings: widget.settings,
                        onSettingsChanged: widget.onSettingsChanged,
                        searchQuery: '',
                        isSelectionMode: _isSelectionMode,
                        onSelectionModeChanged: (mode) =>
                            setState(() => _isSelectionMode = mode),
                        driveTotalBytes: _driveTotalFor(currentLoc.path),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
