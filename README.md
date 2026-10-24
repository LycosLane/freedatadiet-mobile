# FreeDataDiet Mobile

[![Version: 1.6.0](https://img.shields.io/badge/version-1.6.0-blue.svg)](https://github.com/LycosLane)
[![Platform: Android | Linux Mobile](https://img.shields.io/badge/Platform-Android%20%7C%20Linux%20Mobile-0078D6.svg)](https://github.com/LycosLane)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Zero Telemetry](https://img.shields.io/badge/Telemetry-Zero-brightgreen.svg)]()
[![No Ads](https://img.shields.io/badge/Ads-None-success.svg)]()

FreeDataDiet shows what is taking up space on your phone.

Find large files, clear app cache, delete duplicates.

No ads, no subscriptions, no popups.

---

## Disk Explorer

<p align="center">
  <img src="docs/screenshots/freedatadietmobile-folders-dark.png" width="300" alt="FreeDataDiet Disk Explorer">
</p>

See which folders and files use the most space. Tap column headers to sort by name, date, or size. Pinch to zoom in and out.

---

## App Diet

<p align="center">
  <img src="docs/screenshots/freedatadietmobile-apps-dark.png" width="300" alt="FreeDataDiet App Diet">
</p>

See how much space apps use for their cache. Tap any app to open Android settings and clear its cache with one tap.

---

## Filters and Duplicates

<p align="center">
  <img src="docs/screenshots/freedatadietmobile-settings-dark.png" width="300" alt="FreeDataDiet Filters and Preferences">
</p>

Filter what you see. Turn off images to focus on videos, search by file extension like `.pdf` or `.zip`, find duplicate files, and skip folders you do not care about.

---

## We Don't Collect or Sell Your Data

* **No internet access:** The app does not ask for internet permission. It cannot send your files or data anywhere.
* **No tracking:** There are no analytics, no advertising SDKs, and no accounts.
* **No ads:** No ads, no subscriptions, no popups.
* **No fake tools:** No placebo RAM cleaners or fake CPU coolers. You see real files and decide what to delete.
* **Open source:** Free software licensed under the MIT license.
* **Written down:** Read the short [privacy policy](PRIVACY.md).

---

## Permissions

* **All Files Access:** Needed on Android 11+ to read file and folder sizes.
* **Usage Access:** Needed to check app cache sizes directly from Android system settings.
* **See all apps:** Needed to list every installed app in the App Diet view.

---

## Build from Source

```bash
git clone https://github.com/LycosLane/FreeDataDietMobile.git
cd FreeDataDietMobile
flutter pub get
flutter test
flutter run
flutter build apk --release
```

---

## License

MIT License. Created and maintained by [LycosLane](https://github.com/LycosLane).
