/// Pure path helpers: folder exclusion matching, canonicalization, and delete protection.
/// Kept free of dart:io so they are cheap to unit test and safe to use inside isolates.
class PathRules {
  PathRules._();

  /// Normalizes a user-entered exclusion such as ` \Android\data/ ` to `Android/data`.
  /// Returns an empty string when nothing usable remains.
  static String normalizePattern(String raw) {
    final parts = raw
        .trim()
        .replaceAll('\\', '/')
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    return parts.join('/');
  }

  /// Splits a path into canonicalized non-empty segments, resolving `.` and `..` components.
  static List<String> segments(String path) {
    final raw = path.replaceAll('\\', '/').split('/');
    final List<String> result = [];
    for (final part in raw) {
      final trimmed = part.trim();
      if (trimmed.isEmpty || trimmed == '.') continue;
      if (trimmed == '..') {
        if (result.isNotEmpty) {
          result.removeLast();
        }
      } else {
        result.add(trimmed);
      }
    }
    return result;
  }

  /// Last path segment (file or folder name).
  static String baseName(String path) {
    final segs = segments(path);
    return segs.isEmpty ? path : segs.last;
  }

  // OS system root folders that must never be deleted
  static const Set<String> _systemRoots = {
    'system',
    'data',
    'etc',
    'usr',
    'bin',
    'sbin',
    'proc',
    'sys',
    'dev',
    'boot',
    'apex',
    'vendor',
    'product',
    'system_ext',
    'odm',
    'windows',
    'program files',
    'program files (x86)',
  };

  /// High-security delete protection:
  /// - System root folders (/system, /data, /etc, /apex, /bin, /usr, Windows, etc.) are 100% protected.
  /// - Volume roots (/storage, /storage/emulated/0, /storage/XXXX-XXXX, /sdcard) are 100% protected.
  /// - Android system & app directories (/Android, /Android/data, /Android/obb, /Android/media) are 100% protected.
  /// - Critical filesystem metadata (.android_secure, lost+found, .system) are 100% protected.
  static bool isProtectedForDelete(String path) {
    final segs = segments(path);
    if (segs.isEmpty) return true;

    final first = segs.first.toLowerCase();

    // Check system root directories
    if (_systemRoots.contains(first)) {
      return true;
    }

    if (first == 'sdcard') {
      // /sdcard root itself
      if (segs.length == 1) return true;
      final sub = segs[1].toLowerCase();
      // Protect /sdcard/Android and all subfolders (data, obb, media)
      if (sub == 'android') return true;
      if (sub == '.android_secure' || sub == 'lost+found' || sub == '.system') {
        return true;
      }
      return false;
    }

    if (first == 'storage') {
      // /storage/emulated/0 has a 3-segment root, /storage/XXXX-XXXX has a 2-segment root.
      final rootLength = segs.length > 1 && segs[1].toLowerCase() == 'emulated'
          ? 3
          : 2;

      // The volume root itself (/storage, /storage/emulated, /storage/emulated/0, /storage/XXXX-XXXX)
      if (segs.length <= rootLength) return true;

      // Essential system & app directories directly under storage root
      final topFolder = segs[rootLength].toLowerCase();

      // Protect /Android and ALL its subfolders (/Android/data, /Android/obb, /Android/media, etc.)
      if (topFolder == 'android') {
        return true;
      }

      // Protect legacy encrypted app containers and filesystem recovery
      if (topFolder == '.android_secure' ||
          topFolder == 'lost+found' ||
          topFolder == '.system') {
        return true;
      }

      return false;
    }

    return false;
  }

  /// True if [path] lies on (or is) [volumeRoot].
  static bool isUnder(String path, String volumeRoot) {
    final p = segments(path);
    final r = segments(volumeRoot);
    if (r.isEmpty || p.length < r.length) return false;
    for (var i = 0; i < r.length; i++) {
      if (p[i] != r[i]) return false;
    }
    return true;
  }
}

/// Matches paths against exclusion patterns on whole folder-name boundaries.
/// `.git` matches a folder called `.git` but not `.github`; `Android/data` matches that exact folder pair.
class ExclusionMatcher {
  final List<String> _patterns;

  ExclusionMatcher(Iterable<String> patterns)
    : _patterns = patterns
          .map((p) => PathRules.normalizePattern(p).toLowerCase())
          .where((p) => p.isNotEmpty)
          .toList();

  bool matches(String path) {
    if (_patterns.isEmpty) return false;
    final lower = path.replaceAll('\\', '/').toLowerCase();
    for (final p in _patterns) {
      if (lower == p || lower.endsWith('/$p')) return true;
    }
    return false;
  }
}
