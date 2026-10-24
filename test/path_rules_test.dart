import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/core/utils/path_rules.dart';
import 'package:freedatadiet_mobile/models/user_settings.dart';

void main() {
  group('ExclusionMatcher', () {
    test('matches whole folder names, not substrings', () {
      final m = ExclusionMatcher(['.git', '.cache']);
      expect(m.matches('/storage/emulated/0/proj/.git'), true);
      expect(m.matches('/storage/emulated/0/proj/.github'), false);
      expect(m.matches('/storage/emulated/0/x.cache.old'), false);
      expect(m.matches('/storage/emulated/0/app/.cache'), true);
    });

    test('matches multi segment patterns and ignores case', () {
      final m = ExclusionMatcher(['Android/data']);
      expect(m.matches('/storage/emulated/0/android/DATA'), true);
      expect(m.matches('/storage/emulated/0/Android/data/com.x'), false);
      expect(m.matches('/storage/emulated/0/Android'), false);
    });

    test('empty list excludes nothing', () {
      expect(ExclusionMatcher([]).matches('/anything'), false);
    });
  });

  group('PathRules', () {
    test('normalizePattern cleans user input', () {
      expect(PathRules.normalizePattern(r' \Android\data/ '), 'Android/data');
      expect(PathRules.normalizePattern('///'), '');
      expect(PathRules.normalizePattern('.cache'), '.cache');
    });

    test(
      'storage roots, Android folder, and app data/obb are strictly protected',
      () {
        expect(PathRules.isProtectedForDelete('/'), true);
        expect(PathRules.isProtectedForDelete('/storage'), true);
        expect(PathRules.isProtectedForDelete('/storage/emulated'), true);
        expect(PathRules.isProtectedForDelete('/storage/emulated/0'), true);
        expect(
          PathRules.isProtectedForDelete('/storage/emulated/0/Android'),
          true,
        );
        expect(
          PathRules.isProtectedForDelete('/storage/emulated/0/Android/data'),
          true,
        );
        expect(
          PathRules.isProtectedForDelete('/storage/emulated/0/Android/obb'),
          true,
        );
        expect(
          PathRules.isProtectedForDelete(
            '/storage/emulated/0/Android/media/com.whatsapp',
          ),
          true,
        );
        expect(PathRules.isProtectedForDelete('/storage/1A2B-3C4D'), true);
        expect(
          PathRules.isProtectedForDelete('/storage/1A2B-3C4D/Android'),
          true,
        );
        expect(
          PathRules.isProtectedForDelete('/storage/1A2B-3C4D/Android/data'),
          true,
        );
        expect(PathRules.isProtectedForDelete('/sdcard'), true);
        expect(PathRules.isProtectedForDelete('/sdcard/Android'), true);
        expect(PathRules.isProtectedForDelete('/sdcard/Android/data'), true);
        expect(
          PathRules.isProtectedForDelete('/storage/emulated/0/lost+found'),
          true,
        );
        expect(
          PathRules.isProtectedForDelete('/storage/emulated/0/.android_secure'),
          true,
        );
      },
    );

    test('system directories are protected', () {
      expect(PathRules.isProtectedForDelete('/system'), true);
      expect(PathRules.isProtectedForDelete('/data'), true);
      expect(PathRules.isProtectedForDelete('/data/app'), true);
      expect(PathRules.isProtectedForDelete('/etc'), true);
      expect(PathRules.isProtectedForDelete('/usr/bin'), true);
    });

    test('directory traversal attacks with .. are resolved and protected', () {
      expect(
        PathRules.isProtectedForDelete(
          '/storage/emulated/0/Download/../../../system',
        ),
        true,
      );
      expect(
        PathRules.isProtectedForDelete(
          '/storage/emulated/0/Download/../Android/data',
        ),
        true,
      );
    });

    test('normal user folders and files can be deleted', () {
      expect(PathRules.isProtectedForDelete('/storage/emulated/0/DCIM'), false);
      expect(
        PathRules.isProtectedForDelete(
          '/storage/emulated/0/Download/report.pdf',
        ),
        false,
      );
      expect(
        PathRules.isProtectedForDelete('/storage/1A2B-3C4D/Movies/a.mp4'),
        false,
      );
      expect(PathRules.isProtectedForDelete('/home/user/tmp/file.txt'), false);
    });

    test('isUnder respects segment boundaries', () {
      expect(PathRules.isUnder('/storage/1A2B/DCIM', '/storage/1A2B'), true);
      expect(PathRules.isUnder('/storage/1A2B', '/storage/1A2B'), true);
      expect(PathRules.isUnder('/storage/1A2B3/DCIM', '/storage/1A2B'), false);
    });
  });

  group('Excluded folder defaults', () {
    test('defaults are not reported as custom', () {
      expect(const UserSettings().hasCustomExclusions, false);
    });

    test('edited list is custom and restoring defaults clears it', () {
      final edited = const UserSettings().copyWith(
        excludedPatterns: ['.custom'],
      );
      expect(edited.hasCustomExclusions, true);
      final restored = edited.copyWith(
        excludedPatterns: List.of(UserSettings.defaultExcludedPatterns),
      );
      expect(restored.hasCustomExclusions, false);
    });
  });
}
