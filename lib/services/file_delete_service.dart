import 'dart:io' show Directory, File, FileSystemEntity, FileSystemEntityType;
import 'dart:isolate';

import '../core/utils/path_rules.dart';

/// Outcome of a delete operation.
class DeleteResult {
  final int deleted;

  /// Paths that were refused (protected) or could not be removed.
  final List<String> failed;

  const DeleteResult({required this.deleted, required this.failed});

  bool get hasFailures => failed.isNotEmpty;
}

/// Deletes files and folders off the UI isolate and reports what worked and what did not.
class FileDeleteService {
  FileDeleteService._();

  /// Permanently deletes [paths]. Protected paths (volume roots, `Android`) are refused.
  static Future<DeleteResult> deleteItems(List<String> paths) {
    final copy = List<String>.of(paths);
    return Isolate.run(() => deleteSync(copy));
  }

  /// Synchronous implementation, public so tests can run it directly.
  static DeleteResult deleteSync(List<String> paths) {
    var deleted = 0;
    final failed = <String>[];

    for (final path in paths) {
      if (PathRules.isProtectedForDelete(path)) {
        failed.add(path);
        continue;
      }
      try {
        final type = FileSystemEntity.typeSync(path, followLinks: false);
        if (type == FileSystemEntityType.directory) {
          Directory(path).deleteSync(recursive: true);
          deleted++;
        } else if (type == FileSystemEntityType.file ||
            type == FileSystemEntityType.link) {
          File(path).deleteSync();
          deleted++;
        } else {
          // Already gone (for example removed storage): treat as not deleted by us.
          failed.add(path);
        }
      } catch (_) {
        failed.add(path);
      }
    }
    return DeleteResult(deleted: deleted, failed: failed);
  }
}
