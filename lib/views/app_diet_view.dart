import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/size_formatter.dart';
import '../models/app_storage_info.dart';
import '../services/platform_bridge_service.dart';
import 'widgets/app_item_tile.dart';

enum AppSortMode { cacheDesc, totalDesc, nameAsc }

/// Displays installed applications with APK, Data, and Cache metrics.
class AppDietView extends StatefulWidget {
  final bool hasUsageStatsPermission;
  final VoidCallback onRequestPermission;

  const AppDietView({
    super.key,
    required this.hasUsageStatsPermission,
    required this.onRequestPermission,
  });

  @override
  State<AppDietView> createState() => _AppDietViewState();
}

class _AppDietViewState extends State<AppDietView> {
  List<AppStorageInfo> _allApps = [];
  bool _isLoading = false;
  int _loadGeneration = 0;
  int _statsDone = 0;
  String _searchFilter = '';
  AppSortMode _sortMode = AppSortMode.cacheDesc;
  bool _showSystemApps =
      false; // System apps hidden by default, user apps always shown

  @override
  void initState() {
    super.initState();
    _loadAppStats();
  }

  /// Loads the app list instantly (names only), then streams the sizes in small batches
  /// so the user can already scroll and tap while the numbers fill in.
  Future<void> _loadAppStats() async {
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _statsDone = 0;
    });

    final basics = await PlatformBridgeService.getInstalledAppsBasic();
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _allApps = basics;
      _isLoading = false;
    });

    unawaited(_loadStatsInBatches(generation, basics));
  }

  Future<void> _loadStatsInBatches(
    int generation,
    List<AppStorageInfo> basics,
  ) async {
    const batchSize = 24;
    // User apps first: they are what people care about and what they see on top.
    final ordered = [
      ...basics.where((a) => !a.isSystemApp),
      ...basics.where((a) => a.isSystemApp),
    ];

    for (var i = 0; i < ordered.length; i += batchSize) {
      final batch = ordered.sublist(i, math.min(i + batchSize, ordered.length));
      final stats = await PlatformBridgeService.getAppStats(
        batch.map((a) => a.packageName).toList(),
      );
      if (!mounted || generation != _loadGeneration) return;

      setState(() {
        final indexByPackage = {
          for (var k = 0; k < _allApps.length; k++) _allApps[k].packageName: k,
        };
        for (final app in batch) {
          final index = indexByPackage[app.packageName];
          if (index == null) continue;
          final result = stats[app.packageName];
          _allApps[index] = result != null
              ? _allApps[index].withStats(result)
              : _allApps[index].withoutStats();
        }
        _statsDone += batch.length;
      });
    }
  }

  List<AppStorageInfo> get _filteredApps {
    var list = _allApps.where((app) {
      // User apps are always shown. System apps are only shown if checked.
      if (!_showSystemApps && app.isSystemApp) return false;
      if (_searchFilter.isNotEmpty) {
        final query = _searchFilter.toLowerCase();
        final matchesName = app.appName.toLowerCase().contains(query);
        final matchesPkg = app.packageName.toLowerCase().contains(query);
        if (!matchesName && !matchesPkg) return false;
      }
      return true;
    }).toList();

    // Apps whose sizes are still being calculated stay on top when sorting by size, like folders do.
    int pendingFirst(AppStorageInfo a, AppStorageInfo b) {
      if (a.isCalculating == b.isCalculating) return 0;
      return a.isCalculating ? -1 : 1;
    }

    switch (_sortMode) {
      case AppSortMode.cacheDesc:
        list.sort((a, b) {
          final p = pendingFirst(a, b);
          return p != 0 ? p : b.cacheBytes.compareTo(a.cacheBytes);
        });
        break;
      case AppSortMode.totalDesc:
        list.sort((a, b) {
          final p = pendingFirst(a, b);
          return p != 0 ? p : b.totalBytes.compareTo(a.totalBytes);
        });
        break;
      case AppSortMode.nameAsc:
        list.sort(
          (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
        );
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredApps;

    final totalCache = _allApps.fold<int>(0, (sum, a) => sum + a.cacheBytes);
    final totalFootprint = _allApps.fold<int>(
      0,
      (sum, a) => sum + a.totalBytes,
    );
    final maxAppSize = filtered.isNotEmpty
        ? math.max(
            1,
            filtered
                .map(
                  (a) => _sortMode == AppSortMode.cacheDesc
                      ? a.cacheBytes
                      : a.totalBytes,
                )
                .reduce(math.max),
          )
        : 1;
    final isCalculatingStats =
        _allApps.isNotEmpty && _statsDone < _allApps.length;

    return Column(
      children: [
        if (isCalculatingStats)
          LinearProgressIndicator(
            minHeight: 2,
            value: _allApps.isEmpty ? null : _statsDone / _allApps.length,
          ),
        // Usage Stats Permission Banner if not granted
        if (!widget.hasUsageStatsPermission)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.accentAmber.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.accentAmber,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Grant Usage Access for exact app and cache breakdown.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: widget.onRequestPermission,
                  child: const Text(
                    'Grant Access',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // Summary Header Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryMetric(
                    label: 'Total App Footprint',
                    value: SizeFormatter.formatBytes(totalFootprint),
                    color: theme.colorScheme.primary,
                  ),
                  _buildSummaryMetric(
                    label: 'Cleanable Cache',
                    value: SizeFormatter.formatBytes(totalCache),
                    color: AppColors.accentRose,
                  ),
                  _buildSummaryMetric(
                    label: 'Installed Apps',
                    value: '${_allApps.length}',
                    color: AppColors.accentGreen,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Filter & Sort Row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        onChanged: (val) => setState(() => _searchFilter = val),
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Search apps...',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: theme.scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // System Apps toggle chip: user apps always shown, system apps optional
                  FilterChip(
                    label: const Text(
                      'System Apps',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    selected: _showSystemApps,
                    onSelected: (val) => setState(() => _showSystemApps = val),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<AppSortMode>(
                    icon: const Icon(Icons.sort_rounded, size: 20),
                    tooltip: 'Sort by',
                    onSelected: (mode) => setState(() => _sortMode = mode),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: AppSortMode.cacheDesc,
                        child: Text('Cache Size (Largest First)'),
                      ),
                      PopupMenuItem(
                        value: AppSortMode.totalDesc,
                        child: Text('Total Size (Largest First)'),
                      ),
                      PopupMenuItem(
                        value: AppSortMode.nameAsc,
                        child: Text('App Name (A-Z)'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Apps List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? Center(
                  child: Text(
                    'No matching apps found',
                    style: TextStyle(color: theme.hintColor),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAppStats,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final app = filtered[index];
                      final targetBytes = _sortMode == AppSortMode.cacheDesc
                          ? app.cacheBytes
                          : app.totalBytes;
                      final ratio = SizeFormatter.calculateRatio(
                        targetBytes,
                        maxAppSize,
                      );

                      return AppItemTile(
                        app: app,
                        ratio: ratio,
                        onOpenStorageSettings: () =>
                            PlatformBridgeService.openAppStorageSettings(
                              app.packageName,
                            ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
