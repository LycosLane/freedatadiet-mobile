import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/size_formatter.dart';
import '../models/favorite_folder.dart';
import '../models/storage_item.dart';
import '../models/user_settings.dart';
import '../services/duplicate_finder_service.dart';
import '../services/settings_service.dart';
import '../services/storage_scanner_service.dart';
import 'widgets/batch_delete_bar.dart';
import 'widgets/breadcrumb_bar.dart';
import 'widgets/column_header_row.dart';
import 'widgets/delete_confirm_dialog.dart';
import 'widgets/storage_item_tile.dart';

/// Interactive disk usage explorer and cleaner with table header sorting, progressive folder scanning,
/// fluid pinch-to-zoom scaling, bookmark management, and duplicate clustering.
class DiskBrowserView extends StatefulWidget {
  final List<String> rootPaths;
  final UserSettings settings;
  final ValueChanged<UserSettings> onSettingsChanged;
  final String searchQuery;
  final String? activeTypePreset;
  final bool isSelectionMode;
  final ValueChanged<bool> onSelectionModeChanged;
  final VoidCallback onRescanRequested;

  const DiskBrowserView({
    super.key,
    required this.rootPaths,
    required this.settings,
    required this.onSettingsChanged,
    required this.searchQuery,
    this.activeTypePreset,
    required this.isSelectionMode,
    required this.onSelectionModeChanged,
    required this.onRescanRequested,
  });

  @override
  State<DiskBrowserView> createState() => _DiskBrowserViewState();
}

class _DiskBrowserViewState extends State<DiskBrowserView> {
  late String _currentPath;
  List<StorageItem> _items = [];
  bool _isLoading = false;
  final Set<String> _selectedPaths = {};
  StreamSubscription<FolderSizeUpdate>? _folderScanSub;

  double _basePinchScale = 1.0;

  @override
  void initState() {
    super.initState();
    // Default to configured startup path or first root path
    final initialPath = widget.rootPaths.isNotEmpty ? widget.rootPaths.first : widget.settings.defaultStartupPath;
    _currentPath = initialPath.isNotEmpty ? initialPath : '/storage/emulated/0';
    _scanCurrentPath();
  }

  @override
  void dispose() {
    _folderScanSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(DiskBrowserView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final rootPathsChanged = !listEquals(widget.rootPaths, oldWidget.rootPaths);
    final includeSubfoldersChanged = widget.settings.includeSubfolders != oldWidget.settings.includeSubfolders;
    final showHiddenChanged = widget.settings.showHiddenFiles != oldWidget.settings.showHiddenFiles;
    final criteriaChanged = widget.settings.duplicateCriteria.matchSize != oldWidget.settings.duplicateCriteria.matchSize ||
        widget.settings.duplicateCriteria.matchName != oldWidget.settings.duplicateCriteria.matchName ||
        widget.settings.duplicateCriteria.matchTimestamp != oldWidget.settings.duplicateCriteria.matchTimestamp;

    if (rootPathsChanged) {
      if (widget.rootPaths.isNotEmpty) {
        _currentPath = widget.rootPaths.first;
      }
      _scanCurrentPath();
    } else if (includeSubfoldersChanged || showHiddenChanged) {
      _scanCurrentPath();
    } else if (criteriaChanged) {
      // Re-evaluate duplicates on existing items
      setState(() {
        _items = DuplicateFinderService.markDuplicates(
          items: _items,
          criteria: widget.settings.duplicateCriteria,
        );
      });
    }
  }

  Future<void> _scanCurrentPath() async {
    _folderScanSub?.cancel();

    if (widget.settings.includeSubfolders) {
      setState(() => _isLoading = true);
      final pathsToScan = widget.rootPaths.length > 1 ? widget.rootPaths : [_currentPath];

      final deepItems = await StorageScannerService.scanDeepRecursive(
        rootPaths: pathsToScan,
        showHidden: widget.settings.showHiddenFiles,
        excludedPatterns: widget.settings.excludedPatterns,
        duplicateCriteria: widget.settings.duplicateCriteria,
      );

      if (mounted) {
        setState(() {
          _items = deepItems;
          _isLoading = false;
          _selectedPaths.clear();
        });
      }
      return;
    }

    // Step 1: Immediately show shallow directory entries (< 5ms)
    final immediateItems = StorageScannerService.getImmediateShallowItems(
      path: _currentPath,
      showHidden: widget.settings.showHiddenFiles,
      excludedPatterns: widget.settings.excludedPatterns,
    );

    // Tag duplicates in shallow directory view
    final itemsWithDuplicates = DuplicateFinderService.markDuplicates(
      items: immediateItems,
      criteria: widget.settings.duplicateCriteria,
    );

    setState(() {
      _items = itemsWithDuplicates;
      _isLoading = false;
      _selectedPaths.clear();
    });

    // Step 2: Progressively calculate subfolder sizes in background
    final dirPathsToScan = immediateItems.where((i) => i.isDirectory).map((i) => i.path).toList();
    if (dirPathsToScan.isEmpty) return;

    _folderScanSub = StorageScannerService.calculateFolderSizesProgressive(
      dirPaths: dirPathsToScan,
      excludedPatterns: widget.settings.excludedPatterns,
    ).listen((update) {
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((i) => i.path == update.path);
        if (index != -1) {
          _items[index] = _items[index].copyWith(
            size: update.size,
            childCount: update.childCount,
            isScanning: false,
          );
        }
      });
    });
  }

  List<StorageItem> get _visibleItems {
    final combinedSearch = widget.searchQuery.isNotEmpty
        ? widget.searchQuery
        : widget.settings.customFilterText.trim();

    var list = _items.where((item) {
      // 1. Text Search / Custom extension filter
      if (combinedSearch.isNotEmpty) {
        final query = combinedSearch.toLowerCase();
        final matchesName = item.name.toLowerCase().contains(query);
        final matchesExt = item.extension.toLowerCase().contains(query);
        if (!matchesName && !matchesExt) return false;
      }

      // 2. Show duplicates only
      if (widget.settings.showDuplicatesOnly) {
        if (item.isDirectory || !item.isDuplicate) return false;
      }

      // 3. Unified Type Filters (Images, Videos, Audio, Documents, Archives)
      if (widget.settings.hasActiveTypeFilters) {
        if (item.isDirectory) {
          // If subfolders are not included, keep folders visible so user can navigate into them!
          return !widget.settings.includeSubfolders;
        }

        final ext = item.extension.toLowerCase();
        bool matchesAnyType = false;

        if (widget.settings.filterImages &&
            const ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.dng', '.raw', '.gif', '.bmp'].contains(ext)) {
          matchesAnyType = true;
        }
        if (widget.settings.filterVideos &&
            const ['.mp4', '.mkv', '.mov', '.avi', '.webm', '.3gp', '.ts', '.m4v'].contains(ext)) {
          matchesAnyType = true;
        }
        if (widget.settings.filterAudio &&
            const ['.mp3', '.flac', '.m4a', '.wav', '.ogg', '.opus', '.aac', '.wma'].contains(ext)) {
          matchesAnyType = true;
        }
        if (widget.settings.filterDocuments &&
            const ['.pdf', '.doc', '.docx', '.txt', '.epub', '.xlsx', '.xls', '.pptx', '.csv', '.md'].contains(ext)) {
          matchesAnyType = true;
        }
        if (widget.settings.filterArchives &&
            const ['.zip', '.rar', '.7z', '.tar', '.gz', '.apk', '.obb', '.bz2'].contains(ext)) {
          matchesAnyType = true;
        }

        if (!matchesAnyType) return false;
      }

      return true;
    }).toList();

    // Table Column Sorting
    list.sort((a, b) {
      // When sorting by size descending: folders still scanning appear on top!
      if (widget.settings.sortColumn == SortColumn.size && widget.settings.sortDescending) {
        if (a.isScanning && !b.isScanning) return -1;
        if (!a.isScanning && b.isScanning) return 1;
      }

      if (!widget.settings.includeSubfolders) {
        // In hierarchy mode, keep directories grouped on top
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
      }

      final int cmp;
      switch (widget.settings.sortColumn) {
        case SortColumn.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortColumn.date:
          final dateA = a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
          cmp = dateA.compareTo(dateB);
          break;
        case SortColumn.size:
          cmp = a.size.compareTo(b.size);
          break;
      }

      return widget.settings.sortDescending ? -cmp : cmp;
    });

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

  int get _maxItemSize {
    final visible = _visibleItems;
    if (visible.isEmpty) return 1;
    return visible.map((e) => e.size).reduce((a, b) => a > b ? a : b);
  }

  int get _currentFolderTotalBytes {
    return _items.fold<int>(0, (sum, i) => sum + i.size);
  }

  double _computeRatio(StorageItem item) {
    switch (widget.settings.barScalingMode) {
      case BarScalingMode.largestItem:
        return SizeFormatter.calculateRatio(item.size, _maxItemSize);
      case BarScalingMode.folderTotal:
        return SizeFormatter.calculateRatio(item.size, _currentFolderTotalBytes);
      case BarScalingMode.driveTotal:
        return SizeFormatter.calculateRatio(item.size, 64 * 1024 * 1024 * 1024);
    }
  }

  void _onItemTap(StorageItem item) {
    if (widget.isSelectionMode) {
      _toggleSelection(item.path);
    } else {
      if (item.isDirectory) {
        setState(() {
          _currentPath = item.path;
        });
        _scanCurrentPath();
      } else {
        OpenFilex.open(item.path);
      }
    }
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPaths.addAll(_visibleItems.map((e) => e.path));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPaths.clear();
    });
  }

  void _confirmBatchDelete() {
    final selectedItems = _items.where((i) => _selectedPaths.contains(i.path)).toList();
    if (selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => DeleteConfirmDialog(
        selectedItems: selectedItems,
        onConfirmDelete: () async {
          await StorageScannerService.deleteItems(selectedItems.map((e) => e.path).toList());
          widget.onSelectionModeChanged(false);
          _scanCurrentPath();
        },
      ),
    );
  }

  void _showBookmarkDialog() {
    final isFav = widget.settings.favoriteFolders.any((f) => f.path == _currentPath);
    final isStartup = widget.settings.defaultStartupPath == _currentPath;
    final folderName = _currentPath.split('/').where((s) => s.isNotEmpty).lastOrNull ?? 'Folder';
    final nameController = TextEditingController(text: folderName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.folder_special_rounded, color: AppColors.accentAmber, size: 22),
            const SizedBox(width: 8),
            const Text('Folder Bookmark', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentPath,
              style: TextStyle(fontSize: 11.5, color: Theme.of(ctx).hintColor, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Bookmark Label',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isStartup ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isStartup ? AppColors.accentAmber : Theme.of(ctx).hintColor,
              ),
              title: const Text('Default Startup Folder', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                isStartup ? 'Opens automatically on launch' : 'Tap button below to set',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: isStartup
                  ? const Icon(Icons.check, color: AppColors.accentGreen, size: 18)
                  : FilledButton.tonal(
                      onPressed: () {
                        final updated = widget.settings.copyWith(defaultStartupPath: _currentPath);
                        widget.onSettingsChanged(updated);
                        SettingsService.saveSettings(updated);
                        Navigator.of(ctx).pop();
                      },
                      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('Set as Startup', style: TextStyle(fontSize: 11)),
                    ),
            ),
          ],
        ),
        actions: [
          if (isFav)
            TextButton(
              onPressed: () {
                final updatedFavs = widget.settings.favoriteFolders.where((f) => f.path != _currentPath).toList();
                final updated = widget.settings.copyWith(favoriteFolders: updatedFavs);
                widget.onSettingsChanged(updated);
                SettingsService.saveSettings(updated);
                Navigator.of(ctx).pop();
              },
              child: const Text('Remove Bookmark', style: TextStyle(color: AppColors.accentRose)),
            ),
          FilledButton(
            onPressed: () {
              final label = nameController.text.trim().isEmpty ? folderName : nameController.text.trim();
              final updatedFavs = List<FavoriteFolder>.from(widget.settings.favoriteFolders);
              if (!isFav) {
                updatedFavs.add(FavoriteFolder(name: label, path: _currentPath));
              }
              final updated = widget.settings.copyWith(favoriteFolders: updatedFavs);
              widget.onSettingsChanged(updated);
              SettingsService.saveSettings(updated);
              Navigator.of(ctx).pop();
            },
            child: Text(isFav ? 'Save' : 'Add to Favorites'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = _visibleItems;
    final totalSelectedBytes = _items
        .where((i) => _selectedPaths.contains(i.path))
        .fold<int>(0, (sum, i) => sum + i.size);

    final canNavigateUp = !widget.settings.includeSubfolders &&
        _currentPath != '/' &&
        (widget.rootPaths.isEmpty || !widget.rootPaths.contains(_currentPath));

    final isFav = widget.settings.favoriteFolders.any((f) => f.path == _currentPath);
    final isStartup = widget.settings.defaultStartupPath == _currentPath;

    return Column(
      children: [
        // Breadcrumb Trail (when not including subfolders)
        if (!widget.settings.includeSubfolders)
          BreadcrumbBar(
            currentPath: _currentPath,
            canNavigateUp: canNavigateUp,
            isFavorite: isFav,
            isStartup: isStartup,
            onBookmarkPressed: _showBookmarkDialog,
            onNavigateUp: () {
              final parent = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
              setState(() {
                _currentPath = parent.isEmpty ? '/' : parent;
              });
              _scanCurrentPath();
            },
            onNavigateTo: (targetPath) {
              setState(() {
                _currentPath = targetPath;
              });
              _scanCurrentPath();
            },
          )
        else
          // Subfolders included indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            color: AppColors.primary.withValues(alpha: 0.12),
            child: Row(
              children: [
                const Icon(Icons.folder_copy_rounded, size: 15, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Including subfolders: Showing all files in scope',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${visible.length} files',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        // Interactive Table Column Header (Name, Date, Size)
        ColumnHeaderRow(
          activeColumn: widget.settings.sortColumn,
          isDescending: widget.settings.sortDescending,
          isSelectionMode: widget.isSelectionMode,
          textScale: widget.settings.textScale,
          onSortChanged: _onSortChanged,
        ),

        // Items Table with Pinch-to-Zoom
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : visible.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded, size: 48, color: theme.hintColor.withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          Text(
                            'No matching files found',
                            style: TextStyle(color: theme.hintColor, fontSize: 13),
                          ),
                          if (widget.settings.hasActiveTypeFilters || widget.settings.showDuplicatesOnly) ...[
                            const SizedBox(height: 6),
                            TextButton.icon(
                              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                              label: const Text('Reset Active Filters'),
                              onPressed: () {
                                final updated = widget.settings.copyWith(
                                  filterImages: false,
                                  filterVideos: false,
                                  filterAudio: false,
                                  filterDocuments: false,
                                  filterArchives: false,
                                  showDuplicatesOnly: false,
                                  customFilterText: '',
                                );
                                widget.onSettingsChanged(updated);
                                SettingsService.saveSettings(updated);
                              },
                            ),
                          ],
                        ],
                      ),
                    )
                  : GestureDetector(
                      onScaleStart: (details) {
                        _basePinchScale = widget.settings.textScale;
                      },
                      onScaleUpdate: (details) {
                        if (details.pointerCount >= 2) {
                          final newScale = (_basePinchScale * details.scale).clamp(0.8, 1.6);
                          if ((newScale - widget.settings.textScale).abs() > 0.02) {
                            final updated = widget.settings.copyWith(textScale: newScale);
                            widget.onSettingsChanged(updated);
                          }
                        }
                      },
                      onScaleEnd: (details) {
                        SettingsService.saveSettings(widget.settings);
                      },
                      child: RefreshIndicator(
                        onRefresh: _scanCurrentPath,
                        child: ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final item = visible[index];
                            final ratio = _computeRatio(item);
                            final isSelected = _selectedPaths.contains(item.path);

                            return StorageItemTile(
                              item: item,
                              ratio: ratio,
                              isSelectionMode: widget.isSelectionMode,
                              isSelected: isSelected,
                              textScale: widget.settings.textScale,
                              onSelectChanged: (_) => _toggleSelection(item.path),
                              onTap: () => _onItemTap(item),
                              onLongPress: () {
                                if (!widget.isSelectionMode) {
                                  widget.onSelectionModeChanged(true);
                                  _toggleSelection(item.path);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
        ),

        // Batch Delete Action Bar during Selection Mode
        if (widget.isSelectionMode)
          BatchDeleteBar(
            selectedCount: _selectedPaths.length,
            selectedTotalBytes: totalSelectedBytes,
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
}
