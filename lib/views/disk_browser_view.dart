import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/size_formatter.dart';
import '../models/storage_item.dart';
import '../models/user_settings.dart';
import '../services/settings_service.dart';
import '../services/storage_scanner_service.dart';
import 'widgets/batch_delete_bar.dart';
import 'widgets/breadcrumb_bar.dart';
import 'widgets/column_header_row.dart';
import 'widgets/delete_confirm_dialog.dart';
import 'widgets/storage_item_tile.dart';

/// Interactive disk usage explorer and cleaner with table header sorting.
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

  @override
  void initState() {
    super.initState();
    _currentPath = widget.rootPaths.isNotEmpty ? widget.rootPaths.first : '/storage/emulated/0';
    _scanCurrentPath();
  }

  @override
  void didUpdateWidget(DiskBrowserView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rootPaths != oldWidget.rootPaths ||
        widget.settings.includeSubfolders != oldWidget.settings.includeSubfolders ||
        widget.settings.showHiddenFiles != oldWidget.settings.showHiddenFiles ||
        widget.settings.duplicateCriteria.matchSize != oldWidget.settings.duplicateCriteria.matchSize ||
        widget.settings.duplicateCriteria.matchName != oldWidget.settings.duplicateCriteria.matchName ||
        widget.settings.duplicateCriteria.matchTimestamp != oldWidget.settings.duplicateCriteria.matchTimestamp) {
      if (widget.rootPaths.isNotEmpty && !widget.rootPaths.contains(_currentPath) && !_currentPath.startsWith(widget.rootPaths.first)) {
        _currentPath = widget.rootPaths.first;
      }
      _scanCurrentPath();
    }
  }

  Future<void> _scanCurrentPath() async {
    setState(() => _isLoading = true);

    final pathsToScan = widget.settings.includeSubfolders && widget.rootPaths.length > 1
        ? widget.rootPaths
        : [_currentPath];

    final scanned = await StorageScannerService.scanDirectory(
      paths: pathsToScan,
      includeSubfolders: widget.settings.includeSubfolders,
      showHidden: widget.settings.showHiddenFiles,
      excludedPatterns: widget.settings.excludedPatterns,
      duplicateCriteria: widget.settings.duplicateCriteria,
    );

    if (mounted) {
      setState(() {
        _items = scanned;
        _isLoading = false;
        _selectedPaths.clear();
      });
    }
  }

  List<StorageItem> get _visibleItems {
    var list = _items.where((item) {
      // 1. Text Search / Custom extension filter
      if (widget.searchQuery.isNotEmpty) {
        final query = widget.searchQuery.toLowerCase();
        final matchesName = item.name.toLowerCase().contains(query);
        final matchesExt = item.extension.toLowerCase().contains(query);
        if (!matchesName && !matchesExt) return false;
      }

      // 2. Type Presets filter
      if (widget.activeTypePreset != null) {
        if (item.isDirectory) return false;
        final ext = item.extension.toLowerCase();
        switch (widget.activeTypePreset) {
          case 'images':
            if (!const ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.dng', '.raw'].contains(ext)) return false;
            break;
          case 'videos':
            if (!const ['.mp4', '.mkv', '.mov', '.avi', '.webm', '.3gp', '.ts'].contains(ext)) return false;
            break;
          case 'audio':
            if (!const ['.mp3', '.flac', '.m4a', '.wav', '.ogg', '.aac', '.opus'].contains(ext)) return false;
            break;
          case 'archives':
            if (!const ['.zip', '.rar', '.7z', '.tar', '.gz', '.apk', '.obb'].contains(ext)) return false;
            break;
        }
      }

      return true;
    }).toList();

    // Table Column Sorting
    list.sort((a, b) {
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

    return Column(
      children: [
        // Breadcrumb Trail (when not including subfolders)
        if (!widget.settings.includeSubfolders)
          BreadcrumbBar(
            currentPath: _currentPath,
            canNavigateUp: canNavigateUp,
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
          onSortChanged: _onSortChanged,
        ),

        // Items Table
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : visible.isEmpty
                  ? Center(
                      child: Text(
                        'No files found',
                        style: TextStyle(color: theme.hintColor),
                      ),
                    )
                  : RefreshIndicator(
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
