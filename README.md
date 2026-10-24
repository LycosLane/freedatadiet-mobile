# FreeDataDiet Mobile

[![Version: 1.6.2](https://img.shields.io/badge/version-1.6.2-blue.svg)](https://github.com/LycosLane/freedatadiet-mobile)
[![Platform: Android](https://img.shields.io/badge/Platform-Android%2010%2B-0078D6.svg)](https://github.com/LycosLane/freedatadiet-mobile)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Zero Telemetry](https://img.shields.io/badge/Telemetry-Zero-brightgreen.svg)]()
[![No Ads](https://img.shields.io/badge/Ads-None-success.svg)]()

> **Put your mobile storage on a diet.**  
> The official Android companion to [FreeDataDiet (Desktop)](https://github.com/LycosLane/freedatadiet).  
> A fast, lightweight, and 100% private disk usage and app-cache analyzer.

---

## Highlights & Features

* **Interactive Disk Explorer:** Browse internal storage and removable media (SD card, USB-OTG) with proportional usage bars. Sort instantly by size, file name, or modification date.
* **Pinch-to-Zoom & Multiline Wrapping:** Scale text and UI elements smoothly. Long file names wrap naturally so nothing is cut off, even at high zoom levels.
* **Continuous Drag-to-Select:** Select multiple files or folders effortlessly. Simply long-press or start from a checkbox and drag down or up, with automatic edge scrolling.
* **In-App Media Preview:** Fast 24x24 micro-thumbnails in the file list, plus a built-in full-screen swipeable image viewer with pinch-to-zoom using native Android codecs (zero third-party decoder bloat).
* **Subfolder Diff-Grouping:** When scanning subfolders, identically named or matching files are grouped into clean cards. Common values are shown once in the header, while distinct paths and occurrence checkboxes are displayed below with a convenient *"Keep 1st"* preset.
* **Two-Pass Bit-Exact Duplicate Detection:** Rapid candidate pre-filtering by size/name, followed by background isolate SHA-256 hash verification for bit-exact accuracy.
* **Smart Duplicate Cleaning Assistant:** Suggests cleaning sibling duplicate files residing in the same folders to save time, always requiring explicit confirmation before deletion.
* **App & Cache Diet:** Discover which apps consume the most cache and data storage. Jump directly into Android's native app settings to clear cache with a single tap.
* **Hardened Safety & Traverse Protection:** Absolute delete protection for all `/Android` subdirectories (`data`, `obb`, `media`), system volumes, and SD card roots, hardened against path traversal attacks (`..`).
* **120 FPS Resilient IO:** Directory listings, recursive size calculation, and hash computation run in dedicated background worker isolates (`Isolate.run`), keeping the UI silky-smooth even on slow SD cards or degraded USB drives.
* **Fail-Safe Crash Recovery:** Safe defaults fallback on unreadable/interrupted settings, plus a one-click *"Reset All Settings to Factory Defaults"* button in the preferences sheet.

---

## Screenshots

<p align="center">
  <img src="docs/screenshots/freedatadietmobile-folders-dark.png" width="280" alt="FreeDataDiet Disk Explorer">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/screenshots/freedatadietmobile-apps-dark.png" width="280" alt="FreeDataDiet App Diet">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/screenshots/freedatadietmobile-settings-dark.png" width="280" alt="FreeDataDiet Filters and Preferences">
</p>

---

## Privacy & Security by Design

* **Zero Internet Access:** The app does not request or include `android.permission.INTERNET`. Your files, device information, and scan data cannot leave your phone.
* **Zero Telemetry & Tracking:** No analytics SDKs, no crash reporters phoning home, no advertising networks, and no user accounts.
* **No Placebo Tools:** No fake "RAM boosters" or fraudulent "CPU coolers". You inspect real files, real storage, and make informed decisions yourself.
* **Open Source:** Transparent code published under the permissive MIT license.
* **Written Privacy Policy:** Review our straightforward [Privacy Policy](PRIVACY.md).

---

## Required Permissions

To inspect storage and app caches on modern Android systems, FreeDataDiet Mobile requires:

* **All Files Access (`MANAGE_EXTERNAL_STORAGE`):** Required on Android 11+ to crawl directory trees, calculate true folder sizes, and delete selected files.
* **Usage Stats Access (`PACKAGE_USAGE_STATS`):** Used strictly to query installed app cache and storage sizes via Android's `StorageStatsManager`.
* **Query All Packages (`QUERY_ALL_PACKAGES`):** Needed on Android 11+ to list installed applications in the App Diet overview.

---

## Build from Source

### Prerequisites
* Flutter SDK (3.24+ recommended)
* Android SDK (API 34/35)
* Java 17

### Build Steps

```bash
# Clone the repository
git clone https://github.com/LycosLane/freedatadiet-mobile.git
cd freedatadiet-mobile

# Fetch Flutter dependencies
flutter pub get

# Run the test suite (58+ automated tests)
flutter test

# Run code analysis
flutter analyze

# Build debug or release APK
flutter build apk --release
```

The compiled APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Related Projects

* **[FreeDataDiet (Desktop)](https://github.com/LycosLane/freedatadiet):** High-speed disk space analyzer for Windows, Linux, and macOS written in Rust and egui.

---

## License

This project is open-source software licensed under the [MIT License](LICENSE).  
Authored and maintained by [LycosLane](https://github.com/LycosLane).
