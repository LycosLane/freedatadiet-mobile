# Publishing to Google Play

A checklist for the first release. Nothing here has been submitted yet. Check the current Google Play policies before you submit, they change.

## 1. Accounts and one-time setup

1. Create a Google Play Developer account (one-time fee, identity verification required).
2. Choose **Play App Signing** when creating the app. Google keeps the final signing key, you keep an **upload key**.
3. A public **privacy policy URL** is required. Publish [PRIVACY.md](../PRIVACY.md) (for example via GitHub Pages or the raw GitHub link) and enter that URL.

## 2. Create the upload key (once)

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Store the file **outside the repository** (or in `android/`, where `*.jks` is git-ignored) and back it up. Then create `android/key.properties` (also git-ignored):

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=../upload-keystore.jks
```

[build.gradle.kts](../android/app/build.gradle.kts) picks this up automatically. Without the file, release builds fall back to the debug key and **must not be published**.

## 3. Build the bundle

Google Play requires an Android App Bundle:

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`. Increase `version` in `pubspec.yaml` (the number after `+` is the version code and must grow with every upload).

## 4. Sensitive permissions (the hard part)

Three permissions need a **Permissions Declaration Form** in Play Console under *App content*. Google reviews them by hand and may reject the app if the use is not core functionality.

| Permission | Why we need it | Notes for the form |
|---|---|---|
| `MANAGE_EXTERNAL_STORAGE` (All files access) | Measure every folder on internal and external storage, delete files the user selects. | Core use case: file manager / storage analyzer. Without it the app cannot see sizes of folders it does not own. |
| `QUERY_ALL_PACKAGES` | List all installed apps with their cache, data and APK size. | Core use case of the App Diet view. |
| `PACKAGE_USAGE_STATS` | Android only returns per-app storage sizes with this access. | User grants it in system settings. |

Tips:

* Describe the feature in one clear sentence, and attach a short screen recording that shows the feature using the permission.
* Say that nothing leaves the device (no internet permission).
* Be ready for a rejection. If Google refuses `MANAGE_EXTERNAL_STORAGE`, the same app can still be distributed through GitHub releases or F-Droid.

## 5. Data safety form

Answers that match the app:

* Does the app collect or share user data? **No.**
* Is all data encrypted in transit? Not applicable, the app has no network access.
* Can users request data deletion? Not applicable, no data is collected.

## 6. Store listing

* Title: FreeDataDiet
* Short description (80 characters): "See what fills your phone. Clear app cache, find big files and duplicates."
* Screenshots: reuse the images in [docs/screenshots](screenshots).
* Category: Tools.
* Content rating questionnaire: no ads, no user content, no violence.

## 7. Before every upload

* [ ] `flutter analyze` and `flutter test` pass (the manifest test checks that no internet permission was added).
* [ ] Version and version code increased.
* [ ] Built with the real upload key.
* [ ] Release build tested on a real phone: scan, delete, App Diet, unplugging an SD card.
