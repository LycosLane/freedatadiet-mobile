import 'dart:async';
import 'dart:io' show Directory, File;
import 'dart:isolate';

import '../core/utils/path_rules.dart';
import '../models/storage_item.dart';
import 'scan_fs.dart';

/// A chunk of files found by [DeepScan].
class DeepScanBatch {
  final List<StorageItem> items;

  /// True for the last message of a scan.
  final bool done;

  /// True if one of the roots is gone (for example the storage was removed).
  final bool rootMissing;

  /// True if some folders could not be read.
  final bool hadErrors;

  const DeepScanBatch({
    required this.items,
    this.done = false,
    this.rootMissing = false,
    this.hadErrors = false,
  });
}

/// Recursive file listing ("Include subfolders") that streams results in chunks,
/// so files appear while the scan is still running. Cancelling kills the isolate.
class DeepScan {
  static const int _batchSize = 1500;

  final List<String> rootPaths;
  final bool showHidden;
  final List<String> excludedPatterns;

  final StreamController<DeepScanBatch> _controller =
      StreamController<DeepScanBatch>();
  Isolate? _isolate;
  ReceivePort? _port;
  bool _cancelled = false;
  bool _closed = false;

  DeepScan({
    required this.rootPaths,
    required this.showHidden,
    required this.excludedPatterns,
  });

  Stream<DeepScanBatch> get batches => _controller.stream;

  Future<void> start() async {
    final port = ReceivePort();
    _port = port;
    port.listen((msg) {
      if (msg == null) {
        _close(); // worker exited
      } else if (msg is DeepScanBatch && !_controller.isClosed) {
        _controller.add(msg);
      }
    });

    try {
      final isolate = await Isolate.spawn(_worker, <String, Object>{
        'roots': rootPaths,
        'hidden': showHidden,
        'excluded': excludedPatterns,
        'port': port.sendPort,
      }, onExit: port.sendPort);
      if (_cancelled) {
        isolate.kill(priority: Isolate.immediate);
      } else {
        _isolate = isolate;
      }
    } catch (_) {
      _close();
    }
  }

  void cancel() {
    _cancelled = true;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _close();
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    _port?.close();
    if (!_controller.isClosed) _controller.close();
  }

  static void _worker(Map<String, Object> params) {
    final roots = params['roots'] as List<String>;
    final showHidden = params['hidden'] as bool;
    final matcher = ExclusionMatcher(params['excluded'] as List<String>);
    final port = params['port'] as SendPort;

    var buffer = <StorageItem>[];
    var errors = false;
    var missing = false;

    void flush({bool done = false}) {
      port.send(
        DeepScanBatch(
          items: buffer,
          done: done,
          rootMissing: missing,
          hadErrors: errors,
        ),
      );
      buffer = <StorageItem>[];
    }

    for (final rootPath in roots) {
      final root = Directory(rootPath);
      if (!root.existsSync()) {
        missing = true;
        continue;
      }

      final stack = <Directory>[root];
      while (stack.isNotEmpty) {
        final current = stack.removeLast();
        try {
          for (final entity in current.listSync(followLinks: false)) {
            final name = ScanFs.baseName(entity.path);
            if (!showHidden && name.startsWith('.')) continue;
            if (matcher.matches(entity.path)) continue;

            if (entity is Directory) {
              stack.add(entity);
            } else if (entity is File) {
              buffer.add(
                StorageItem(
                  path: entity.path,
                  name: name,
                  isDirectory: false,
                  size: ScanFs.safeLength(entity),
                  lastModified: ScanFs.safeModified(entity),
                  extension: ScanFs.extensionOf(name),
                ),
              );
              if (buffer.length >= _batchSize) flush();
            }
          }
        } catch (_) {
          errors = true;
        }
      }
      if (!root.existsSync()) missing = true;
    }

    flush(done: true);
  }
}
