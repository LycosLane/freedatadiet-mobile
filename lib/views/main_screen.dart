import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/storage_volume.dart';
import '../models/user_settings.dart';
import '../services/platform_bridge_service.dart';
import '../services/settings_service.dart';
import 'app_diet_view.dart';
import 'disk_browser_view.dart';
import 'settings_dialog.dart';

enum ActiveScope {
  internal('Internal Storage', Icons.phone_android_rounded),
  sdCard('External SD Card', Icons.sd_card_rounded),
  allStorages('All Storages (Internal + SD)', Icons.storage_rounded),
  appsDiet('Apps & Cache Diet', Icons.apps_rounded),
  images('Images Only', Icons.image_rounded),
  videos('Videos Only', Icons.video_collection_rounded),
  audio('Audio Only', Icons.audiotrack_rounded),
  archives('Archives & APKs', Icons.folder_zip_rounded);

  final String label;
  final IconData icon;
  const ActiveScope(this.label, this.icon);
}

/// Main application screen with unified scope selector, search/custom filter, and content views.
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
  ActiveScope _currentScope = ActiveScope.internal;
  List<StorageVolume> _volumes = [];
  bool _hasStoragePermission = true;
  bool _hasUsageStatsPermission = true;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isSelectionMode = false;
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndVolumes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndVolumes() async {
    final permissions = await PlatformBridgeService.checkPermissions();
    final volumes = await PlatformBridgeService.getStorageVolumes();

    if (mounted) {
      setState(() {
        _hasStoragePermission = permissions['hasStoragePermission'] ?? true;
        _hasUsageStatsPermission = permissions['hasUsageStatsPermission'] ?? true;
        _volumes = volumes;
      });
    }
  }

  List<String> get _activeRootPaths {
    final primaryVolume = _volumes.where((v) => v.isPrimary).firstOrNull ?? _volumes.firstOrNull;
    final externalVolume = _volumes.where((v) => !v.isPrimary).firstOrNull;

    switch (_currentScope) {
      case ActiveScope.internal:
        return [primaryVolume?.path ?? '/storage/emulated/0'];
      case ActiveScope.sdCard:
        return externalVolume != null ? [externalVolume.path] : [primaryVolume?.path ?? '/storage/emulated/0'];
      case ActiveScope.allStorages:
        return _volumes.map((v) => v.path).toList();
      case ActiveScope.images:
      case ActiveScope.videos:
      case ActiveScope.audio:
      case ActiveScope.archives:
        return _volumes.map((v) => v.path).toList();
      case ActiveScope.appsDiet:
        return [];
    }
  }

  String? get _activeTypePreset {
    switch (_currentScope) {
      case ActiveScope.images:
        return 'images';
      case ActiveScope.videos:
        return 'videos';
      case ActiveScope.audio:
        return 'audio';
      case ActiveScope.archives:
        return 'archives';
      default:
        return null;
    }
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
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
    final hasExternalSD = _volumes.any((v) => !v.isPrimary);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Filter name, .pdf, .xmp, *.sidecar...',
                  hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : _buildScopeDropdown(hasExternalSD),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _isSearching ? 'Close Search' : 'Search / Custom Filter',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (_currentScope != ActiveScope.appsDiet) ...[
            // Toggle Recursive Flat View
            IconButton(
              icon: Icon(
                widget.settings.isRecursiveFlatView ? Icons.layers_rounded : Icons.folder_open_rounded,
                color: widget.settings.isRecursiveFlatView ? theme.colorScheme.primary : null,
              ),
              tooltip: widget.settings.isRecursiveFlatView ? 'Switch to Hierarchy View' : 'Recursive Flat View (All Files)',
              onPressed: () {
                final updated = widget.settings.copyWith(
                  isRecursiveFlatView: !widget.settings.isRecursiveFlatView,
                );
                widget.onSettingsChanged(updated);
                SettingsService.saveSettings(updated);
              },
            ),
            // Select for Deletion Mode
            IconButton(
              icon: Icon(
                _isSelectionMode ? Icons.check_circle_rounded : Icons.checklist_rounded,
                color: _isSelectionMode ? AppColors.accentRose : null,
              ),
              tooltip: _isSelectionMode ? 'Exit Selection Mode' : 'Select for Deletion',
              onPressed: () => setState(() => _isSelectionMode = !_isSelectionMode),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettingsDialog,
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
            child: _currentScope == ActiveScope.appsDiet
                ? AppDietView(
                    hasUsageStatsPermission: _hasUsageStatsPermission,
                    onRequestPermission: () async {
                      await PlatformBridgeService.requestUsageStatsPermission();
                      await _checkPermissionsAndVolumes();
                    },
                  )
                : DiskBrowserView(
                    key: ValueKey('${_currentScope.name}_$_refreshCounter'),
                    rootPaths: _activeRootPaths,
                    settings: widget.settings,
                    searchQuery: _searchQuery,
                    activeTypePreset: _activeTypePreset,
                    isSelectionMode: _isSelectionMode,
                    onSelectionModeChanged: (mode) => setState(() => _isSelectionMode = mode),
                    onRescanRequested: () => setState(() => _refreshCounter++),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeDropdown(bool hasExternalSD) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<ActiveScope>(
        value: _currentScope,
        isDense: true,
        borderRadius: BorderRadius.circular(8),
        selectedItemBuilder: (context) {
          return ActiveScope.values.map((scope) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(scope.icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  scope.label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            );
          }).toList();
        },
        items: [
          const DropdownMenuItem(
            value: ActiveScope.internal,
            child: _DropdownItem(icon: Icons.phone_android_rounded, label: 'Internal Storage'),
          ),
          if (hasExternalSD)
            const DropdownMenuItem(
              value: ActiveScope.sdCard,
              child: _DropdownItem(icon: Icons.sd_card_rounded, label: 'External SD Card'),
            ),
          const DropdownMenuItem(
            value: ActiveScope.allStorages,
            child: _DropdownItem(icon: Icons.storage_rounded, label: 'All Storages (Cross-Drive)'),
          ),
          const DropdownMenuItem(
            value: ActiveScope.appsDiet,
            child: _DropdownItem(icon: Icons.apps_rounded, label: 'Apps & Cache Diet'),
          ),
          const DropdownMenuItem(enabled: false, child: Divider(height: 1)),
          const DropdownMenuItem(
            value: ActiveScope.images,
            child: _DropdownItem(icon: Icons.image_rounded, label: 'Images Only'),
          ),
          const DropdownMenuItem(
            value: ActiveScope.videos,
            child: _DropdownItem(icon: Icons.video_collection_rounded, label: 'Videos Only'),
          ),
          const DropdownMenuItem(
            value: ActiveScope.audio,
            child: _DropdownItem(icon: Icons.audiotrack_rounded, label: 'Audio Only'),
          ),
          const DropdownMenuItem(
            value: ActiveScope.archives,
            child: _DropdownItem(icon: Icons.folder_zip_rounded, label: 'Archives & APKs'),
          ),
        ],
        onChanged: (newScope) {
          if (newScope != null) {
            setState(() {
              _currentScope = newScope;
              _isSelectionMode = false;
            });
          }
        },
      ),
    );
  }
}

class _DropdownItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DropdownItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13.5)),
      ],
    );
  }
}
