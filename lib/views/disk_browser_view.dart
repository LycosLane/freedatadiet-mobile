import 'dart:async';
import 'dart:io' show Directory;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../core/utils/path_rules.dart';
import '../core/utils/size_formatter.dart';
import '../models/saved_location.dart';
import '../models/storage_item.dart';
import '../models/user_settings.dart';
import '../services/deep_scan.dart';
import '../services/duplicate_finder_service.dart';
import '../services/folder_size_scan.dart';
import '../services/item_view_filter.dart';
import '../services/settings_service.dart';
import '../services/storage_scanner_service.dart';
import 'widgets/batch_delete_bar.dart';
import 'widgets/breadcrumb_bar.dart';
import 'widgets/column_header_row.dart';
import 'widgets/browser_status_widgets.dart';
import 'widgets/delete_flow.dart';
import 'widgets/drag_select_list_view.dart';
import 'widgets/subfolder_diff_list_view.dart';
import '../services/subfolder_grouper.dart';
import 'image_viewer_screen.dart';

/// Interactive disk usage explorer and cleaner with table header sorting, progressive folder scanning,
/// fluid pinch-to-zoom scaling, folder favoriting, and duplicate clustering.
class DiskBrowserView extends StatefulWidget {
  final List<String> rootPaths;
  final UserSettings settings;
  final ValueChanged<UserSettings> onSettingsChanged;
  final String searchQuery;
  final bool isSelectionMode;
  final ValueChanged<bool> onSelectionModeChanged;

  /// Capacity of the volume that contains [rootPaths], used by the "Total Disk Capacity" bar mode.
  final int? driveTotalBytes;

  const DiskBrowserView({
    super.key,
    required this.rootPaths,
    required this.settings,
    required this.onSettingsChanged,
    required this.searchQuery,
    required this.isSelectionMode,
    required this.onSelectionModeChanged,
    this.driveTotalBytes,
  });

  @override
  State<DiskBrowserView> createState() => DiskBrowserViewState();
}

class DiskBrowserViewState extends State<DiskBrowserView> {
  static const Duration _flushInterval = Duration(milliseconds: 150);

  late String _currentPath;
  List<StorageItem> _items = [];
  Map<String, int> _indexByPath = {};
  final Set<String> _selectedPaths = {};

  // Scan state
  int _generation = 0;
  FolderSizeScan? _folderScan;
  StreamSubscription<FolderSizeUpdate>? _folderScanSub;
  DeepScan? _deepScan;
  StreamSubscription<DeepScanBatch>? _deepScanSub;
  bool _isDeepScanning = false;
  bool _scanHadErrors = false;
  bool _storageGone = false;

  // Batched UI updates so streaming results never cause a rebuild storm
  final Map<String, FolderSizeUpdate> _pendingFolderUpdates = {};
  final List<StorageItem> _pendingDeepItems = [];
  Timer? _flushTimer;

  // Cached filtered + sorted list (recomputed only when its inputs change)
  int _itemsRevision = 0;
  int? _visibleSignature;
  List<StorageItem> _visibleCache = const [];
  int _maxVisibleSize = 1;
  int _itemsTotalBytes = 0;

  double _basePinchScale = 1.0;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.rootPaths.isNotEmpty
        ? widget.rootPaths.first
        : '/storage/emulated/0';
    _scanCurrentPath();
  }

  @override
  void dispose() {
    _cancelScans();
    _flushTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(DiskBrowserView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.settings;
    final now = widget.settings;

    final rootPathsChanged = !listEquals(widget.rootPaths, oldWidget.rootPaths);
    final scanInputsChanged =
        now.includeSubfolders != old.includeSubfolders ||
        now.showHiddenFiles != old.showHiddenFiles ||
        !listEquals(now.excludedPatterns, old.excludedPatterns);
    final criteriaChanged =
        now.duplicateCriteria.matchSize != old.duplicateCriteria.matchSize ||
        now.duplicateCriteria.matchName != old.duplicateCriteria.matchName ||
        now.duplicateCriteria.matchTimestamp !=
            old.duplicateCriteria.matchTimestamp;

    if (oldWidget.isSelectionMode && !widget.isSelectionMode) {
      _selectedPaths.clear();
    }

    if (rootPathsChanged) {
      if (widget.rootPaths.isNotEmpty) {
        _currentPath = widget.rootPaths.first;
      }
      _scanCurrentPath();
    } else if (scanInputsChanged) {
      _scanCurrentPath();
    } else if (criteriaChanged) {
      // Re-evaluate duplicates on existing items
      setState(() {
        _items = DuplicateFinderService.markDuplicates(
          items: _items,
          criteria: widget.settings.duplicateCriteria,
        );
        _itemsChanged();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Public API used by MainScreen
  // ---------------------------------------------------------------------------

  /// Starts a fresh scan of the current folder (for example after a storage volume was mounted).
  void rescan() => _scanCurrentPath();

  /// Handles the system back gesture. Returns true if it was consumed.
  bool handleBack() {
    if (widget.isSelectionMode) {
      widget.onSelectionModeChanged(false);
      setState(_selectedPaths.clear);
      return true;
    }
    if (_canNavigateUp) {
      _navigateUp();
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Scanning
  // ---------------------------------------------------------------------------

  void _cancelScans() {
    _folderScanSub?.cancel();
    _folderScanSub = null;
    _folderScan?.cancel();
    _folderScan = null;
    _deepScanSub?.cancel();
    _deepScanSub = null;
    _deepScan?.cancel();
    _deepScan = null;
    _pendingFolderUpdates.clear();
    _pendingDeepItems.clear();
  }

  void _itemsChanged() {
    _itemsRevision++;
    _indexByPath = {for (var i = 0; i < _items.length; i++) _items[i].path: i};
  }

  Future<void> _scanCurrentPath() async {
    _cancelScans();
    _generation++;
    final generation = _generation;

    setState(() {
      _selectedPaths.clear();
      _storageGone = false;
      _scanHadErrors = false;
    });

    if (widget.settings.includeSubfolders) {
      await _startDeepScan(generation);
    } else {
      _startFolderScan(generation);
    }
  }

  void _startFolderScan(int generation) {
    var listing = StorageScannerService.listDirectory(
      path: _currentPath,
      showHidden: widget.settings.showHiddenFiles,
      excludedPatterns: widget.settings.excludedPatterns,
    );

    if (!listing.pathExists) {
      // The folder vanished (deleted elsewhere or storage removed): climb to the nearest folder that still exists.
      final fallback = _nearestExistingPath();
      if (fallback == null) {
        setState(() {
          _items = [];
          _isDeepScanning = false;
          _storageGone = true;
          _itemsChanged();
        });
        return;
      }
      _currentPath = fallback;
      listing = StorageScannerService.listDirectory(
        path: _currentPath,
        showHidden: widget.settings.showHiddenFiles,
        excludedPatterns: widget.settings.excludedPatterns,
      );
    }

    final itemsWithDuplicates = DuplicateFinderService.markDuplicates(
      items: listing.items,
      criteria: widget.settings.duplicateCriteria,
    );

    setState(() {
      _items = itemsWithDuplicates;
      _isDeepScanning = false;
      _scanHadErrors = listing.hadErrors;
      _itemsChanged();
    });

    final dirPaths = listing.items
        .where((i) => i.isDirectory)
        .map((i) => i.path)
        .toList();
    if (dirPaths.isEmpty) return;

    final scan = FolderSizeScan(
      dirPaths: dirPaths,
      excludedPatterns: widget.settings.excludedPatterns,
    );
    _folderScan = scan;
    _folderScanSub = scan.updates.listen((update) {
      if (!mounted || generation != _generation) return;
      _pendingFolderUpdates[update.path] = update;
      if (update.missing && !Directory(_currentPath).existsSync()) {
        // The storage went away while measuring: start over so the user gets a clear state.
        _scanCurrentPath();
        return;
      }
      _scheduleFlush();
    });
    scan.start();
  }

  Future<void> _startDeepScan(int generation) async {
    setState(() {
      _items = [];
      _isDeepScanning = true;
      _itemsChanged();
    });

    final paths = widget.rootPaths.length > 1
        ? widget.rootPaths
        : [_currentPath];
    final scan = DeepScan(
      rootPaths: paths,
      showHidden: widget.settings.showHiddenFiles,
      excludedPatterns: widget.settings.excludedPatterns,
    );
    _deepScan = scan;
    _deepScanSub = scan.batches.listen((batch) {
      if (!mounted || generation != _generation) return;
      _pendingDeepItems.addAll(batch.items);
      if (batch.hadErrors) _scanHadErrors = true;
      if (batch.done) {
        _finishDeepScan(batch.rootMissing);
      } else {
        _scheduleFlush();
      }
    });
    await scan.start();
  }

  void _finishDeepScan(bool rootMissing) {
    _flushTimer?.cancel();
    _flushTimer = null;
    setState(() {
      _items.addAll(_pendingDeepItems);
      _pendingDeepItems.clear();
      _items = DuplicateFinderService.markDuplicates(
        items: _items,
        criteria: widget.settings.duplicateCriteria,
      );
      _isDeepScanning = false;
      _storageGone = rootMissing && _items.isEmpty;
      _itemsChanged();
    });
  }

  void _scheduleFlush() {
    _flushTimer ??= Timer(_flushInterval, _flush);
  }

  void _flush() {
    _flushTimer = null;
    if (!mounted) return;
    setState(() {
      if (_pendingDeepItems.isNotEmpty) {
        _items.addAll(_pendingDeepItems);
        _pendingDeepItems.clear();
        _itemsRevision++;
      }
      if (_pendingFolderUpdates.isNotEmpty) {
        for (final update in _pendingFolderUpdates.values) {
          final index = _indexByPath[update.path];
          if (index == null || index >= _items.length) continue;
          _items[index] = _items[index].copyWith(
            size: update.size,
            childCount: update.childCount,
            isScanning: !update.isFinal,
            hasErrors: update.hadErrors,
          );
        }
        _pendingFolderUpdates.clear();
        _itemsRevision++;
      }
    });
  }

  /// Closest ancestor of the current folder (inside the scan root) that still exists, or null if none.
  String? _nearestExistingPath() {
    final root = widget.rootPaths.isNotEmpty ? widget.rootPaths.first : null;
    var path = _currentPath;
    while (true) {
      try {
        if (Directory(path).existsSync()) return path;
      } catch (_) {
        return null;
      }
      if (root == null || path == root) return null;
      final slash = path.lastIndexOf('/');
      if (slash <= 0) return null;
      path = path.substring(0, slash);
      if (!PathRules.isUnder(path, root)) return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Filtering & sorting (cached)
  // ---------------------------------------------------------------------------

  List<StorageItem> _visibleItems() {
    final s = widget.settings;
    final signature = Object.hashAll([
      _itemsRevision,
      widget.searchQuery,
      s.customFilterText,
      s.showImages,
      s.showVideos,
      s.showAudio,
      s.showDocuments,
      s.showArchives,
      s.includeSubfolders,
      s.showHiddenFiles,
      s.showDuplicatesOnly,
      s.sortColumn,
      s.sortDescending,
    ]);
    if (signature == _visibleSignature) return _visibleCache;

    final list = ItemViewFilter.apply(
      items: _items,
      settings: s,
      searchQuery: widget.searchQuery,
    );

    var max = 1;
    for (final item in list) {
      if (item.size > max) max = item.size;
    }
    var total = 0;
    for (final item in _items) {
      total += item.size;
    }

    _visibleSignature = signature;
    _visibleCache = list;
    _maxVisibleSize = max;
    _itemsTotalBytes = total;
    return list;
  }

  void _onSortChanged(SortColumn col, bool desc) {
    final updated = widget.settings.copyWith(
      sortColumn: col,
      sortDescending: desc,
    );
    widget.onSettingsChanged(updated);
    SettingsService.saveSettings(updated);
  }

  double _computeRatio(StorageItem item) {
    switch (widget.settings.barScalingMode) {
      case BarScalingMode.largestItem:
        return SizeFormatter.calculateRatio(item.size, _maxVisibleSize);
      case BarScalingMode.folderTotal:
        return SizeFormatter.calculateRatio(item.size, _itemsTotalBytes);
      case BarScalingMode.driveTotal:
        return SizeFormatter.calculateRatio(
          item.size,
          widget.driveTotalBytes ?? _itemsTotalBytes,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation & selection
  // ---------------------------------------------------------------------------

  bool get _canNavigateUp =>
      !widget.settings.includeSubfolders &&
      _currentPath != '/' &&
      (widget.rootPaths.isEmpty || !widget.rootPaths.contains(_currentPath));

  void _navigateTo(String path) {
    setState(() => _currentPath = path);
    _scanCurrentPath();
  }

  void _navigateUp() {
    final slash = _currentPath.lastIndexOf('/');
    final parent = slash <= 0 ? '/' : _currentPath.substring(0, slash);
    _navigateTo(parent);
  }

  void _onItemTap(StorageItem item) {
    if (widget.isSelectionMode) {
      _toggleSelection(item.path);
    } else if (item.isDirectory) {
      _navigateTo(item.path);
    } else if (ItemViewFilter.isImage(item.path)) {
      final visibleImages = _visibleItems()
          .where((i) => !i.isDirectory && ItemViewFilter.isImage(i.path))
          .toList();
      final imgIndex = visibleImages.indexWhere((i) => i.path == item.path);
      if (imgIndex != -1) {
        ImageViewerScreen.show(
          context: context,
          items: visibleImages,
          initialIndex: imgIndex,
        );
      } else {
        OpenFilex.open(item.path);
      }
    } else {
      OpenFilex.open(item.path);
    }
  }

  void _toggleSelection(String path) {
    setState(() {
      if (!_selectedPaths.remove(path)) {
        _selectedPaths.add(path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPaths.addAll(_visibleItems().map((e) => e.path));
    });
  }

  void _deselectAll() {
    setState(_selectedPaths.clear);
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
      );
  }

  Future<void> _confirmBatchDelete() async {
    final selectedItems = _items
        .where((i) => _selectedPaths.contains(i.path))
        .toList();
    if (selectedItems.isEmpty) return;
    final attempted = await DeleteFlow.run(context, selectedItems);
    if (!attempted || !mounted) return;
    widget.onSelectionModeChanged(false);
    _scanCurrentPath();
  }

  // ---------------------------------------------------------------------------

  void _toggleFavoriteFolder(StorageItem folder) {
    final existingIndex = widget.settings.locations.indexWhere(
      (l) => l.path == folder.path,
    );
    final updatedLocations = List<SavedLocation>.from(
      widget.settings.locations,
    );

    if (existingIndex != -1) {
      updatedLocations.removeAt(existingIndex);
      _showMessage('Removed "${folder.name}" from favorites');
    } else {
      updatedLocations.add(
        SavedLocation(
          id: 'fav_${folder.path}',
          name: folder.name,
          path: folder.path,
          type: 'favorite',
        ),
      );
      _showMessage('Saved "${folder.name}" to top-left menu favorites');
    }

    final updatedSettings = widget.settings.copyWith(
      locations: updatedLocations,
    );
    widget.onSettingsChanged(updatedSettings);
    SettingsService.saveSettings(updatedSettings);
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = _visibleItems();
    final totalSelectedBytes = _items
        .where((i) => _selectedPaths.contains(i.path))
        .fold<int>(0, (sum, i) => sum + i.size);

    // Determine if single selected item is a folder and whether it's already favorited
    final singleSelectedItem = _selectedPaths.length == 1
        ? _items.where((i) => _selectedPaths.contains(i.path)).firstOrNull
        : null;
    final canFavorite =
        singleSelectedItem != null && singleSelectedItem.isDirectory;
    final isFavorite =
        canFavorite &&
        widget.settings.locations.any((l) => l.path == singleSelectedItem.path);

    return Column(
      children: [
        // Breadcrumb Trail (when not including subfolders)
        if (!widget.settings.includeSubfolders)
          BreadcrumbBar(
            currentPath: _currentPath,
            canNavigateUp: _canNavigateUp,
            onNavigateUp: _navigateUp,
            onNavigateTo: _navigateTo,
          )
        else
          SubfolderBanner(
            isScanning: _isDeepScanning,
            visibleCount: visible.length,
          ),

        if (_scanHadErrors && !_storageGone) const UnreadableNote(),

        // Interactive Table Column Header (Name, Date, Size)
        ColumnHeaderRow(
          activeColumn: widget.settings.sortColumn,
          isDescending: widget.settings.sortDescending,
          isSelectionMode: widget.isSelectionMode,
          textScale: widget.settings.textScale,
          onSortChanged: _onSortChanged,
        ),

        // Items Table with Pinch-to-Zoom
        Expanded(child: _buildBody(theme, visible)),

        // Batch Action Bar during Selection Mode
        if (widget.isSelectionMode)
          BatchDeleteBar(
            selectedCount: _selectedPaths.length,
            selectedTotalBytes: totalSelectedBytes,
            canFavorite: canFavorite,
            isFavorite: isFavorite,
            onToggleFavorite: canFavorite
                ? () => _toggleFavoriteFolder(singleSelectedItem)
                : null,
            onSelectAll: _selectAll,
            onDeselectAll: _deselectAll,
            onDeletePressed: _confirmBatchDelete,
            onCancelSelection: () {
              widget.onSelectionModeChanged(false);
              _deselectAll();
            },
          ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, List<StorageItem> visible) {
    if (_storageGone) {
      return CenteredMessage(
        icon: Icons.sd_card_alert_rounded,
        title: 'Storage not available',
        subtitle: 'It may have been removed. Reconnect it and try again.',
        action: FilledButton.tonal(
          onPressed: _scanCurrentPath,
          child: const Text('Try again'),
        ),
      );
    }

    if (visible.isEmpty) {
      if (_isDeepScanning) {
        return const Center(child: CircularProgressIndicator());
      }
      return CenteredMessage(
        icon: Icons.folder_open_rounded,
        title: 'No matching files found',
        action: widget.settings.hasActiveFilters
            ? TextButton.icon(
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Reset Visibility Filters'),
                onPressed: () {
                  final updated = widget.settings.copyWith(
                    showImages: true,
                    showVideos: true,
                    showAudio: true,
                    showDocuments: true,
                    showArchives: true,
                    showDuplicatesOnly: false,
                    customFilterText: '',
                  );
                  widget.onSettingsChanged(updated);
                  SettingsService.saveSettings(updated);
                },
              )
            : null,
      );
    }

    final childWidget = widget.settings.includeSubfolders
        ? SubfolderDiffListView(
            entries: SubfolderGrouper.group(
              items: visible,
              settings: widget.settings,
            ),
            selectedPaths: _selectedPaths,
            isSelectionMode: widget.isSelectionMode,
            textScale: widget.settings.textScale,
            onToggleSelection: _toggleSelection,
            onSelectAllInGroup: (entry) {
              setState(() {
                final allSelected = entry.occurrences.every(
                  (i) => _selectedPaths.contains(i.path),
                );
                if (allSelected) {
                  for (final i in entry.occurrences) {
                    _selectedPaths.remove(i.path);
                  }
                } else {
                  for (final i in entry.occurrences) {
                    _selectedPaths.add(i.path);
                  }
                }
              });
            },
            onKeepFirstInGroup: (entry) {
              setState(() {
                if (entry.occurrences.isNotEmpty) {
                  _selectedPaths.remove(entry.occurrences.first.path);
                  for (int i = 1; i < entry.occurrences.length; i++) {
                    _selectedPaths.add(entry.occurrences[i].path);
                  }
                  if (!widget.isSelectionMode) {
                    widget.onSelectionModeChanged(true);
                  }
                }
              });
            },
            onItemTap: _onItemTap,
            onItemLongPress: (item) {
              if (!widget.isSelectionMode) {
                widget.onSelectionModeChanged(true);
                _toggleSelection(item.path);
              }
            },
            onRefresh: _scanCurrentPath,
          )
        : DragSelectListView(
            items: visible,
            selectedPaths: _selectedPaths,
            isSelectionMode: widget.isSelectionMode,
            textScale: widget.settings.textScale,
            computeRatio: _computeRatio,
            onToggleSelection: _toggleSelection,
            onRangeSelection: (paths) {
              setState(() {
                _selectedPaths
                  ..clear()
                  ..addAll(paths);
              });
            },
            onItemTap: _onItemTap,
            onItemLongPress: (item) {
              if (!widget.isSelectionMode) {
                widget.onSelectionModeChanged(true);
                _toggleSelection(item.path);
              }
            },
            onRefresh: _scanCurrentPath,
          );

    return GestureDetector(
      onScaleStart: (details) {
        _basePinchScale = widget.settings.textScale;
      },
      onScaleUpdate: (details) {
        if (details.pointerCount >= 2) {
          final newScale = (_basePinchScale * details.scale).clamp(0.8, 1.6);
          if ((newScale - widget.settings.textScale).abs() > 0.02) {
            widget.onSettingsChanged(
              widget.settings.copyWith(textScale: newScale),
            );
          }
        }
      },
      onScaleEnd: (details) {
        SettingsService.saveSettings(widget.settings);
      },
      child: childWidget,
    );
  }
}
