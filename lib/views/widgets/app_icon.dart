import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/platform_bridge_service.dart';

/// App launcher icon loaded lazily per visible row and cached, so the list never waits for icons.
class AppIcon extends StatefulWidget {
  final String packageName;
  final double size;

  const AppIcon({super.key, required this.packageName, this.size = 42});

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  static const int _maxCached = 400;
  static final Map<String, Uint8List?> _cache = {};
  static final Map<String, Future<Uint8List?>> _inFlight = {};

  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(widget.packageName);
  }

  @override
  void didUpdateWidget(AppIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) {
      _future = _load(widget.packageName);
    }
  }

  static Future<Uint8List?> _load(String pkg) {
    if (_cache.containsKey(pkg)) return Future.value(_cache[pkg]);
    return _inFlight.putIfAbsent(pkg, () async {
      final bytes = await PlatformBridgeService.getAppIcon(pkg);
      if (_cache.length >= _maxCached) _cache.remove(_cache.keys.first);
      _cache[pkg] = bytes;
      _inFlight.remove(pkg);
      return bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = Container(
      width: widget.size,
      height: widget.size,
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: Icon(
        Icons.android_rounded,
        size: widget.size * 0.57,
        color: theme.colorScheme.primary,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<Uint8List?>(
          future: _future,
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes == null) return fallback;
            return Image.memory(
              bytes,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => fallback,
            );
          },
        ),
      ),
    );
  }
}
