<p align="center">
  <img src="assets/icons/app_icon.png" width="128" alt="FreeDataDiet White Fedora Icon" />
</p>

# FreeDataDiet Mobile

[![Version: 1.6.12](https://img.shields.io/badge/version-1.6.12-blue.svg)](https://github.com/LycosLane/freedatadiet-mobile)
[![Platform: Android](https://img.shields.io/badge/Platform-Android%2010%2B-0078D6.svg)](https://github.com/LycosLane/freedatadiet-mobile)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Zero Telemetry](https://img.shields.io/badge/Telemetry-Zero-brightgreen.svg)]()
[![No Ads](https://img.shields.io/badge/Ads-None-success.svg)]()

> **The official mobile companion to [FreeDataDiet](https://github.com/LycosLane/freedatadiet).**  
> Put your mobile storage on a diet. Fast, private disk usage and app-cache analyzer for Android.  
> Find large files, clear cache, and remove duplicates with zero ads and zero tracking.

---

## Disk Explorer

<p align="center">
  <img src="docs/screenshots/freedatadietmobile-folders-dark.png" width="320" alt="FreeDataDiet Disk Explorer">
</p>

See which folders and files use the most space.
* **Visual size bars:** Color bars show heavy folders immediately.
* **Fast sorting:** Tap headers to sort by file size, date, or name.
* **Multiline names:** Pinch to zoom in. Long file names wrap so nothing is cut off.
* **Drag-to-select:** Touch and drag down to select multiple files at once.
* **Safe delete:** System directories and core Android folders are protected from deletion.

---

## App Diet

<p align="center">
  <img src="docs/screenshots/freedatadietmobile-apps-dark.png" width="290" alt="FreeDataDiet App Diet Dark">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/screenshots/freedatadietmobile-apps-bright.png" width="290" alt="FreeDataDiet App Diet Light">
</p>

See how much space apps use for their cache and storage. Supports both dark and light modes.
* **Find heavy caches:** Lists apps sorted from largest cache to smallest.
* **One-tap clear:** Tap any app to open Android system settings and clear its cache.
* **No fake cleaners:** Uses native Android system stats. No fake RAM boosters or battery tools.

---

## Filters and Duplicates

<p align="center">
  <img src="docs/screenshots/freedatadietmobile-settings-dark.png" width="320" alt="FreeDataDiet Filters and Preferences">
</p>

Filter what you see and clean redundant files.
* **Category filters:** Turn off images, videos, or archives to focus on what matters.
* **Extension search:** Filter by file type like `.mp4`, `.pdf`, or `.zip`.
* **In-app preview:** Tap any photo to view it full-screen and zoom before deleting.
* **Duplicate grouping:** Subfolder duplicates are grouped with paths shown side by side.
* **Keep 1st:** Select extra duplicate copies with one tap.
* **Folder Assistant:** Cleaning a duplicate offers to select other duplicates in the same folder.

---

## Privacy and Security

* **No internet access:** The app does not request network permission (`android.permission.INTERNET`). Your files cannot leave your phone.
* **No ads:** No banners, no video popups, and no paid subscriptions.
* **No tracking:** No analytics, no crash reports sent to third parties, and no accounts.
* **Open source:** Free software under the MIT license. Read our [Privacy Policy](PRIVACY.md).

---

## Required Permissions

* **All Files Access (`MANAGE_EXTERNAL_STORAGE`):** Needed on Android 11+ to calculate folder sizes and delete selected files.
* **Usage Stats Access (`PACKAGE_USAGE_STATS`):** Needed to check app cache sizes directly from Android system settings.
* **Query All Packages (`QUERY_ALL_PACKAGES`):** Needed on Android 11+ to show installed apps in the App Diet tab.

---

## Installation

### Option 1: Direct APK Download
Download and install the latest signed APK from the [**GitHub Releases**](https://github.com/LycosLane/freedatadiet-mobile/releases) page.

> **Android 14/15 note:** If Usage Access is grayed out after sideloading directly from a browser, open **App info -> three-dot menu (top right) -> Allow restricted settings**, then enable Usage Access.

### Option 2: F-Droid / Droid-ify / Neo Store (Recommended)
Add the LycosLane F-Droid repository for 1-tap installation and automatic updates:

1. Install **F-Droid**, **Droid-ify**, or **Neo Store** on your Android device.
2. Open **Repositories -> Add repository** and paste this URL:
   `https://lycoslane.github.io/fdroid/repo`
3. Refresh repositories, search for **FreeDataDiet**, and tap **Install**.

### Option 3: Automatic Updates with Obtainium
[Obtainium](https://github.com/ImranR98/Obtainium/releases) lets you install and update Android apps directly from GitHub Releases with one tap:

1. Install Obtainium from its [GitHub Releases](https://github.com/ImranR98/Obtainium/releases) page (Obtainium can also track and update itself automatically).
2. Open Obtainium, tap **Add App**, and paste this repository URL:
   `https://github.com/LycosLane/freedatadiet-mobile`
3. Tap **Add**, then **Install**. Future releases will appear automatically with a 1-tap **Update** button.

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
