/// Application constants and defaults.
class AppConstants {
  AppConstants._();

  static const String appName = 'FreeDataDiet';
  static const String appVersion = '1.6.4';

  // Desktop-aligned badges
  static const String badgeDir = '[DIR]';
  static const String badgeFile = '[FILE]';
  static const String badgeSys = '[SYS]';
  static const String badgeLink = '[LINK]';

  // Default exclusions
  static const List<String> defaultExcludedPatterns = [
    '.git',
    '.thumbnails',
    'Android/data',
    '.cache',
  ];
}
