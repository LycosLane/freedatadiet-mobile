# FreeDataDiet Mobile

[![Version: 1.4.0](https://img.shields.io/badge/version-1.4.0-blue.svg)](https://github.com/LycosLane)
[![Platform: Android | Linux Mobile](https://img.shields.io/badge/Platform-Android%20%7C%20Linux%20Mobile-0078D6.svg)](https://github.com/LycosLane)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Zero Telemetry](https://img.shields.io/badge/Telemetry-Zero-brightgreen.svg)]()
[![No Ads](https://img.shields.io/badge/Ads-None-success.svg)]()

FreeDataDiet shows what is taking up space on your phone.

Find large files, clear app cache, delete duplicates.

No ads. No subscriptions. No fake cleaner tools.

---

## What It Does

<p align="center">
  <img src="docs/screenshots/overview.png" width="340" alt="FreeDataDiet Mobile Screenshot">
</p>

* **Disk Explorer:** See which folders and files use the most space.
* **App Diet:** See how much space each app uses for its cache. Clear it with one tap in Android settings.
* **Duplicate Finder:** Spot identical files across folders.
* **Custom Filters:** Turn off images to see only videos, or filter by file extension.

---

## We Don't Collect or Sell Your Data

* **No internet access:** The app does not ask for internet permission. It cannot send your files or data anywhere.
* **No tracking:** There are no analytics, no advertising SDKs, and no accounts.
* **No ads:** Completely ad-free with zero popups or subscriptions.
* **No fake tools:** No placebo RAM cleaners or fake CPU coolers. You see real files and decide what to delete.
* **Open source:** Free software licensed under the MIT license.

---

## Permissions

* **All Files Access:** Needed on Android 11+ to read file and folder sizes.
* **Usage Access:** Needed to check app cache sizes directly from Android system settings.

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
