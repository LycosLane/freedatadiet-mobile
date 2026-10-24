import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the privacy promise: the shipped manifest must never request network access,
/// and no broad permission may sneak in unnoticed.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();

  List<String> requested() =>
      RegExp(r'<uses-permission[^>]*android:name="([^"]+)"([^>]*)/>')
          .allMatches(manifest)
          .where((m) => !m.group(2)!.contains('tools:node="remove"'))
          .map((m) => m.group(1)!)
          .toList();

  test('release manifest requests no network permission', () {
    expect(
      requested().where((p) => p.contains('INTERNET') || p.contains('NETWORK')),
      isEmpty,
    );
  });

  test('only the expected permissions are requested', () {
    expect(requested().toSet(), {
      'android.permission.MANAGE_EXTERNAL_STORAGE',
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.PACKAGE_USAGE_STATS',
      'android.permission.QUERY_ALL_PACKAGES',
    });
  });

  test('app data is not backed up', () {
    expect(manifest.contains('android:allowBackup="false"'), true);
    expect(
      manifest.contains(
        'android:dataExtractionRules="@xml/data_extraction_rules"',
      ),
      true,
    );
  });

  test('file provider overrides open_filex with secure filepaths', () {
    expect(manifest.contains('@xml/filepaths'), true);
    final filepathsXml = File('android/app/src/main/res/xml/filepaths.xml')
        .readAsStringSync();
    expect(filepathsXml.contains('root-path'), false);
  });
}
