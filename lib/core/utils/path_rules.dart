/// Pure path helpers: folder exclusion matching and delete protection.
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

  /// Splits a path into non-empty segments.
  static List<String> segments(String path) =>
      path.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty).toList();

  /// Last path segment (file or folder name).
  static String baseName(String path) {
    final segs = segments(path);
    return segs.isEmpty ? path : segs.last;
  }

  /// Delete protection: volume roots, the storage mount folder and the top-level
  /// `Android` folder of a volume must never be removed from inside the app.
  static bool isProtectedForDelete(String path) {
    final segs = segments(path);
    if (segs.isEmpty) return true;

    final first = segs.first.toLowerCase();
    if (first == 'sdcard') {
      // /sdcard and /sdcard/Android
      return segs.length == 1 ||
          (segs.length == 2 && segs[1].toLowerCase() == 'android');
    }
    if (first == 'storage') {
      // /storage/emulated/0 has a 3 segment root, /storage/XXXX-XXXX has a 2 segment root.
      final rootLength = segs.length > 1 && segs[1].toLowerCase() == 'emulated'
          ? 3
          : 2;
      if (segs.length <= rootLength) return true;
      if (segs.length == rootLength + 1 &&
          segs[rootLength].toLowerCase() == 'android') {
        return true;
      }
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
