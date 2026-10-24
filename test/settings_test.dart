import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/models/saved_location.dart';
import 'package:freedatadiet_mobile/models/user_settings.dart';
import 'package:freedatadiet_mobile/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserSettings & SavedLocation Tests', () {
    test('Default visibility values are opt-out (all true)', () {
      const settings = UserSettings();
      expect(settings.textScale, 1.0);
      expect(settings.showImages, true);
      expect(settings.showVideos, true);
      expect(settings.showAudio, true);
      expect(settings.showDocuments, true);
      expect(settings.showArchives, true);
      expect(settings.showHiddenFiles, false);
      expect(settings.includeSubfolders, false);
      expect(settings.showDuplicatesOnly, false);
      expect(settings.locations.length, 5);
      expect(settings.locations.first.id, 'internal');
    });

    test('Disabling images sets hasActiveFilters to true', () {
      const settings = UserSettings();
      expect(settings.hasActiveFilters, false);

      final noImages = settings.copyWith(showImages: false);
      expect(noImages.showImages, false);
      expect(noImages.hasActiveFilters, true);
    });

    test('SavedLocation serialization roundtrip', () {
      const location = SavedLocation(
        id: 'fav_podcasts',
        name: 'Podcasts',
        path: '/storage/emulated/0/Podcasts',
        type: 'favorite',
      );

      final map = location.toMap();
      final restored = SavedLocation.fromMap(map);

      expect(restored.id, 'fav_podcasts');
      expect(restored.name, 'Podcasts');
      expect(restored.path, '/storage/emulated/0/Podcasts');
      expect(restored.type, 'favorite');
      expect(restored.isFavorite, true);
    });

    test('SettingsService roundtrip and resetToDefaults', () async {
      SharedPreferences.setMockInitialValues({});
      final initial = await SettingsService.loadSettings();
      expect(initial.showHiddenFiles, false);

      final modified = initial.copyWith(
        showHiddenFiles: true,
        customFilterText: 'mp4',
      );
      await SettingsService.saveSettings(modified);

      final loaded = await SettingsService.loadSettings();
      expect(loaded.showHiddenFiles, true);
      expect(loaded.customFilterText, 'mp4');

      final reset = await SettingsService.resetToDefaults();
      expect(reset.showHiddenFiles, false);
      expect(reset.customFilterText, '');

      final afterResetLoaded = await SettingsService.loadSettings();
      expect(afterResetLoaded.showHiddenFiles, false);
      expect(afterResetLoaded.customFilterText, '');
    });
  });
}
