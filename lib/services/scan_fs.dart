import 'dart:io' show File, FileSystemEntity;

import '../core/utils/path_rules.dart';

/// Small filesystem helpers shared by the scanners (they run inside isolates, so they stay static and pure).
class ScanFs {
  ScanFs._();

  static String baseName(String path) => PathRules.baseName(path);

  static int safeLength(File file) {
    try {
      return file.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  static DateTime? safeModified(FileSystemEntity entity) {
    try {
      return entity.statSync().modified;
    } catch (_) {
      return null;
    }
  }

  static String extensionOf(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < name.length - 1) {
      return name.substring(dotIndex).toLowerCase();
    }
    return '';
  }
}
