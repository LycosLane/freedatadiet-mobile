import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import '../models/duplicate_rule.dart';
import '../models/storage_item.dart';

/// Analyzes storage items and tags duplicates based on enabled criteria checkboxes.
/// Supports two-pass bit-exact hash verification (4KB Prefix -> Full SHA-256) in a background isolate.
class DuplicateFinderService {
  DuplicateFinderService._();

  /// Scans items and returns a list with items updated with duplicate flags and group IDs.
  static List<StorageItem> markDuplicates({
    required List<StorageItem> items,
    required DuplicateMatchCriteria criteria,
  }) {
    if (!criteria.isEnabled) {
      return items
          .map((i) => i.copyWith(isDuplicate: false, clearDuplicateGroup: true))
          .toList();
    }

    // Only compare files, not directories
    final fileItems = items.where((item) => !item.isDirectory).toList();
    if (fileItems.length < 2) return items;

    final Map<String, List<StorageItem>> clusters = {};

    for (final item in fileItems) {
      final key = _buildKey(item, criteria);
      if (key == null) continue;
      clusters.putIfAbsent(key, () => []).add(item);
    }

    final Map<String, String> duplicatePathToGroupId = {};
    int groupIndex = 1;

    for (final entry in clusters.entries) {
      if (entry.value.length >= 2) {
        final groupId = 'dup_$groupIndex';
        groupIndex++;
        for (final item in entry.value) {
          duplicatePathToGroupId[item.path] = groupId;
        }
      }
    }

    return items.map((item) {
      final groupId = duplicatePathToGroupId[item.path];
      if (groupId != null) {
        return item.copyWith(isDuplicate: true, duplicateGroupId: groupId);
      }
      return item.copyWith(isDuplicate: false, clearDuplicateGroup: true);
    }).toList();
  }

  /// Two-pass bit-exact hash verification:
  /// Pass 1: 4KB Prefix hash (eliminates ~99.9% false positives instantly)
  /// Pass 2: Full streaming SHA-256 for collision survivors
  /// Runs off the UI thread in a background isolate.
  static Future<List<StorageItem>> verifyWithHashes({
    required List<StorageItem> items,
    required DuplicateMatchCriteria criteria,
  }) async {
    if (!criteria.verifyHash || items.length < 2) {
      return markDuplicates(items: items, criteria: criteria);
    }

    final preFiltered = markDuplicates(items: items, criteria: criteria);
    final candidatePaths = preFiltered
        .where((i) => i.isDuplicate && i.duplicateGroupId != null)
        .map((i) => (path: i.path, size: i.size, group: i.duplicateGroupId!))
        .toList();

    if (candidatePaths.length < 2) {
      return preFiltered;
    }

    // Run isolate hashing
    final verifiedClusters = await Isolate.run(
      () => _isolateVerifyHashes(candidatePaths),
    );

    return items.map((item) {
      final groupId = verifiedClusters[item.path];
      if (groupId != null) {
        return item.copyWith(isDuplicate: true, duplicateGroupId: groupId);
      }
      return item.copyWith(isDuplicate: false, clearDuplicateGroup: true);
    }).toList();
  }

  static Map<String, String> _isolateVerifyHashes(
    List<({String path, int size, String group})> candidates,
  ) {
    final Map<String, List<({String path, int size, String group})>>
    byInitialGroup = {};
    for (final c in candidates) {
      byInitialGroup.putIfAbsent(c.group, () => []).add(c);
    }

    final Map<String, String> verifiedPathToGroup = {};
    int groupIndex = 1;

    for (final group in byInitialGroup.values) {
      if (group.length < 2) continue;

      // Pass 1: 4KB Prefix hash
      final Map<String, List<({String path, int size, String group})>>
      prefixMap = {};

      for (final item in group) {
        try {
          final file = File(item.path);
          if (!file.existsSync()) continue;
          final raf = file.openSync(mode: FileMode.read);
          final bytesToRead = math.min(4096, item.size);
          final buffer = raf.readSync(bytesToRead);
          raf.closeSync();
          final prefixDigest = sha256.convert(buffer).toString();
          prefixMap.putIfAbsent(prefixDigest, () => []).add(item);
        } catch (_) {
          // Skip unreadable files
        }
      }

      // Pass 2: Full hash for survivors
      for (final prefixList in prefixMap.values) {
        if (prefixList.length < 2) continue;

        final Map<String, List<({String path, int size, String group})>>
        fullHashMap = {};

        for (final item in prefixList) {
          try {
            if (item.size <= 4096) {
              // Prefix was already the entire file!
              fullHashMap.putIfAbsent('p1_verified', () => []).add(item);
            } else {
              final file = File(item.path);
              final bytes = file.readAsBytesSync();
              final fullDigest = sha256.convert(bytes).toString();
              fullHashMap.putIfAbsent(fullDigest, () => []).add(item);
            }
          } catch (_) {
            // Skip unreadable files
          }
        }

        for (final verifiedGroup in fullHashMap.values) {
          if (verifiedGroup.length >= 2) {
            final gid = 'dup_h$groupIndex';
            groupIndex++;
            for (final item in verifiedGroup) {
              verifiedPathToGroup[item.path] = gid;
            }
          }
        }
      }
    }

    return verifiedPathToGroup;
  }

  static String? _buildKey(StorageItem item, DuplicateMatchCriteria criteria) {
    if (item.size <= 0 && criteria.matchSize) return null;

    final parts = <String>[];

    if (criteria.matchName) {
      parts.add('NAME:${item.name.toLowerCase()}');
    }
    if (criteria.matchSize) {
      parts.add('SIZE:${item.size}');
    }
    if (criteria.matchTimestamp) {
      final ms = item.lastModified?.millisecondsSinceEpoch ?? 0;
      if (ms > 0) {
        parts.add('TIME:$ms');
      } else {
        return null;
      }
    }

    return parts.isEmpty ? null : parts.join('|');
  }
}
