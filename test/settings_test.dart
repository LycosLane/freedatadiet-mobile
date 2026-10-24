import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/models/favorite_folder.dart';
import 'package:freedatadiet_mobile/models/user_settings.dart';

void main() {
  group('UserSettings & FavoriteFolder Tests', () {
    test('Default values are correct', () {
      const settings = UserSettings();
      expect(settings.textScale, 1.0);
      expect(settings.showDuplicatesOnly, false);
      expect(settings.hasActiveTypeFilters, false);
      expect(settings.favoriteFolders.length, 3);
      expect(settings.defaultStartupPath, '/storage/emulated/0');
    });

    test('copyWith updates fields as expected', () {
      const settings = UserSettings();
      final updated = settings.copyWith(
        textScale: 1.25,
        filterVideos: true,
        showDuplicatesOnly: true,
        defaultStartupPath: '/storage/emulated/0/Download',
      );

      expect(updated.textScale, 1.25);
      expect(updated.filterVideos, true);
      expect(updated.hasActiveTypeFilters, true);
      expect(updated.showDuplicatesOnly, true);
      expect(updated.defaultStartupPath, '/storage/emulated/0/Download');
    });

    test('FavoriteFolder serialization roundtrip', () {
      const folder = FavoriteFolder(
        name: 'Podcasts',
        path: '/storage/emulated/0/Podcasts',
        isDefaultStartup: true,
      );

      final map = folder.toMap();
      final restored = FavoriteFolder.fromMap(map);

      expect(restored.name, 'Podcasts');
      expect(restored.path, '/storage/emulated/0/Podcasts');
      expect(restored.isDefaultStartup, true);
    });
  });
}
