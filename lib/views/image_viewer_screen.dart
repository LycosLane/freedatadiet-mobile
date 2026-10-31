import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../core/utils/size_formatter.dart';
import '../models/storage_item.dart';
import '../services/item_view_filter.dart';
import '../services/platform_bridge_service.dart';
import 'widgets/video_player_item_view.dart';

/// Lightweight in-app media viewer supporting images and video playback.
/// Supports swiping between media in the current folder, pinch-to-zoom for photos,
/// and video playback controls.
class ImageViewerScreen extends StatefulWidget {
  final List<StorageItem> items;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  static Future<void> show({
    required BuildContext context,
    required List<StorageItem> items,
    required int initialIndex,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            ImageViewerScreen(items: items, initialIndex: initialIndex),
      ),
    );
  }

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _showChrome = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(
      0,
      widget.items.isEmpty ? 0 : widget.items.length - 1,
    );
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleChrome() {
    setState(() {
      _showChrome = !_showChrome;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black),
        body: const Center(
          child: Text(
            'No images to display',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final currentItem = widget.items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable Image View with Pinch-to-Zoom
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              if (ItemViewFilter.isVideo(item.path)) {
                return VideoPlayerItemView(
                  key: ValueKey(item.path),
                  path: item.path,
                  isCurrent: index == _currentIndex,
                  onToggleChrome: _toggleChrome,
                );
              }

              return GestureDetector(
                onTap: _toggleChrome,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 6.0,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: Image.file(
                      File(item.path),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded || frame != null) {
                              return child;
                            }
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white54,
                              ),
                            );
                          },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.broken_image_rounded,
                                size: 56,
                                color: Colors.white54,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Cannot decode image format',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Top Header Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            top: _showChrome ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 4,
                left: 8,
                right: 8,
                bottom: 8,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentItem.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_currentIndex + 1} of ${widget.items.length} • ${SizeFormatter.formatBytes(currentItem.size)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Open with external app',
                    onPressed: () async {
                      try {
                        await PlatformBridgeService.openFile(currentItem.path);
                      } on PlatformException catch (e) {
                        if (context.mounted) {
                          final message = e.code == 'NO_APP'
                              ? 'No application installed to open this file'
                              : (e.message ?? 'Could not open file');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to open file: $e'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
