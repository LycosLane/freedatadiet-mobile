import 'dart:async';
import 'dart:io' show Directory, File;
import 'dart:isolate';

import '../core/utils/path_rules.dart';
import 'scan_fs.dart';

/// Size information for one folder, streamed while it is being measured.
class FolderSizeUpdate {
  final String path;
  final int size;
  final int childCount;

  /// False for running totals, true once the folder has been fully measured.
  final bool isFinal;

  /// True if some sub-folders could not be read (size is a lower bound).
  final bool hadErrors;

  /// True if the folder disappeared while scanning (for example the storage was removed).
  final bool missing;

  const FolderSizeUpdate({
    required this.path,
    required this.size,
    required this.childCount,
    this.isFinal = true,
    this.hadErrors = false,
    this.missing = false,
  });
}

/// Measures folder sizes on a few background isolates and streams progress.
/// Calling [cancel] really stops the work (the isolates are killed), so navigating
/// quickly never leaves scans running in the background.
class FolderSizeScan {
  static const int _maxWorkers = 3;

  final List<String> dirPaths;
  final List<String> excludedPatterns;

  final StreamController<FolderSizeUpdate> _controller =
      StreamController<FolderSizeUpdate>();
  final List<Isolate> _isolates = [];
  ReceivePort? _port;
  bool _cancelled = false;
  bool _closed = false;
  int _liveWorkers = 0;

  FolderSizeScan({required this.dirPaths, required this.excludedPatterns});

  Stream<FolderSizeUpdate> get updates => _controller.stream;

  /// Starts the workers. Safe to call once.
  Future<void> start() async {
    if (dirPaths.isEmpty) {
      _close();
      return;
    }

    final port = ReceivePort();
    _port = port;
    port.listen((msg) {
      if (msg == null) {
        // Worker exit signal (sent via onExit, also when a worker crashes).
        _liveWorkers--;
        if (_liveWorkers <= 0) _close();
      } else if (msg is Map && !_controller.isClosed) {
        _controller.add(
          FolderSizeUpdate(
            path: msg['path'] as String,
            size: msg['size'] as int,
            childCount: msg['childCount'] as int,
            isFinal: msg['final'] as bool,
            hadErrors: msg['errors'] as bool,
            missing: msg['missing'] as bool,
          ),
        );
      }
    });

    final workerCount = dirPaths.length < _maxWorkers
        ? dirPaths.length
        : _maxWorkers;
    final shares = List.generate(workerCount, (_) => <String>[]);
    for (var i = 0; i < dirPaths.length; i++) {
      shares[i % workerCount].add(dirPaths[i]);
    }
    _liveWorkers = workerCount;

    for (final share in shares) {
      if (_cancelled) {
        _liveWorkers--;
        continue;
      }
      try {
        final isolate = await Isolate.spawn(_worker, <String, Object>{
          'paths': share,
          'excluded': excludedPatterns,
          'port': port.sendPort,
        }, onExit: port.sendPort);
        if (_cancelled) {
          isolate.kill(priority: Isolate.immediate);
        } else {
          _isolates.add(isolate);
        }
      } catch (_) {
        _liveWorkers--;
      }
    }
    if (_liveWorkers <= 0) _close();
  }

  /// Stops all work immediately and closes the stream.
  void cancel() {
    _cancelled = true;
    for (final isolate in _isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
    _isolates.clear();
    _close();
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    _port?.close();
    if (!_controller.isClosed) _controller.close();
  }

  static void _worker(Map<String, Object> params) {
    final paths = params['paths'] as List<String>;
    final matcher = ExclusionMatcher(params['excluded'] as List<String>);
    final port = params['port'] as SendPort;

    for (final path in paths) {
      _measure(path, matcher, port);
    }
  }

  static void _measure(
    String rootPath,
    ExclusionMatcher matcher,
    SendPort port,
  ) {
    void send(int size, int count, bool isFinal, bool errors, bool missing) {
      port.send({
        'path': rootPath,
        'size': size,
        'childCount': count,
        'final': isFinal,
        'errors': errors,
        'missing': missing,
      });
    }

    final root = Directory(rootPath);
    if (!root.existsSync()) {
      send(0, 0, true, false, true);
      return;
    }

    var bytes = 0;
    var items = 0;
    var errors = false;
    final stack = <Directory>[root];
    final clock = Stopwatch()..start();
    var lastReport = 0;

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      try {
        for (final child in current.listSync(followLinks: false)) {
          if (matcher.matches(child.path)) continue;
          if (child is File) {
            bytes += ScanFs.safeLength(child);
            items++;
          } else if (child is Directory) {
            stack.add(child);
            items++;
          }
        }
      } catch (_) {
        errors = true;
      }

      // Running total so the user sees the number grow instead of a blank spinner.
      if (clock.elapsedMilliseconds - lastReport > 400) {
        lastReport = clock.elapsedMilliseconds;
        send(bytes, items, false, errors, false);
      }
    }

    // If the root vanished while scanning, the result is not trustworthy.
    final stillThere = root.existsSync();
    send(bytes, items, true, errors, !stillThere);
  }
}
