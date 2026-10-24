# FreeDataDiet Mobile

[![Version: 1.6.2](https://img.shields.io/badge/version-1.6.2-blue.svg)](https://github.com/LycosLane/freedatadiet-mobile)
[![Platform: Android](https://img.shields.io/badge/Platform-Android%2010%2B-0078D6.svg)](https://github.com/LycosLane/freedatadiet-mobile)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Zero Telemetry](https://img.shields.io/badge/Telemetry-Zero-brightgreen.svg)]()
[![No Ads](https://img.shields.io/badge/Ads-None-success.svg)]()

> **Is your phone running out of space? Put your storage on a diet.**  
> Find what uses your storage, clear app cache, and delete duplicate files.  
> 100% private. No ads. No subscriptions. No fake cleaner tools.

The official Android companion to [FreeDataDiet (Desktop)](https://github.com/LycosLane/freedatadiet).

---

<p align="center">
  <img src="docs/screenshots/freedatadietmobile-folders-dark.png" width="270" alt="FreeDataDiet Disk Explorer">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/screenshots/freedatadietmobile-apps-dark.png" width="270" alt="FreeDataDiet App Diet">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/screenshots/freedatadietmobile-settings-dark.png" width="270" alt="FreeDataDiet Filters and Preferences">
</p>

---

## What FreeDataDiet Does

Most cleaner apps show ads, push subscriptions, and use fake animations.  
FreeDataDiet is an honest tool that puts you in control of your storage.

### 1. See what uses your storage
* **Visual size bars:** Color bars show which folders use the most space.
* **Sort fast:** Tap headers to sort by file size, date, or name.
* **Full names:** Pinch to zoom. Long file names wrap onto multiple lines without truncation.

### 2. Clear app cache in seconds
* Social and video apps collect gigabytes of cached media in the background.
* The **App Diet** tab lists your apps from largest cache to smallest.
* Tap any app to open Android system settings and clear its cache.

### 3. Find and remove duplicate files
* Remove duplicate photos and files saved across multiple folders.
* **Full-screen preview:** Tap any image to view it full-screen and zoom before deleting.
* **Side-by-side view:** See duplicates grouped with their folder locations. Use **Keep 1st** to select extra copies in one tap.
* **Folder Assistant:** Cleaning a duplicate offers to select other duplicates in the same folder.

### 4. Select multiple files with one swipe
* Do not tap checkboxes one by one.
* Touch and drag down the screen to select multiple files or folders at once.

### 5. Safe file deletion
* Android system folders and core app data cannot be deleted.
* You see every file selected and confirm deletion yourself.

---

## Privacy and Security

* **No internet access:** The app does not request network access (`android.permission.INTERNET`). Your files cannot leave your phone.
* **No ads:** No banners, no video popups, and no paid tiers.
* **No tracking:** No analytics, no crash reports sent to third parties, and no accounts.
* **No fake tools:** No fake memory boosters or battery tools.
* **Open source:** Licensed under the MIT license. Read our [Privacy Policy](PRIVACY.md).

---

## Permissions

Android requires these permissions to scan and show app sizes:

* **All Files Access (`MANAGE_EXTERNAL_STORAGE`):** Required on Android 11+ to calculate folder sizes and delete selected files.
* **Usage Stats Access (`PACKAGE_USAGE_STATS`):** Used to read app cache sizes from Android system storage settings.
* **Query All Packages (`QUERY_ALL_PACKAGES`):** Needed on Android 11+ to show installed apps in the App Diet tab.

---

## Build from Source

```bash
# Clone repository
git clone https://github.com/LycosLane/freedatadiet-mobile.git
cd freedatadiet-mobile

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run on connected device
flutter run
```

---

## Related Projects

* **[FreeDataDiet (Desktop)](https://github.com/LycosLane/freedatadiet):** Fast disk space analyzer for Windows, Linux, and macOS written in Rust and egui.

---

## License

MIT License © 2026 LycosLane
