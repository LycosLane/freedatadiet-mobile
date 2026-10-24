# FreeDataDiet Mobile

[![Version: 1.4.0](https://img.shields.io/badge/version-1.4.0-blue.svg)](https://github.com/LycosLane)
[![Platform: Android | Linux Mobile](https://img.shields.io/badge/Platform-Android%20%7C%20Linux%20Mobile-0078D6.svg)](https://github.com/LycosLane)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Zero Telemetry](https://img.shields.io/badge/Telemetry-Zero-brightgreen.svg)]()
[![No Ads](https://img.shields.io/badge/Ads-None-success.svg)]()

FreeDataDiet shows what is taking up space on your phone, SD cards, and USB drives. It helps you find large files, clear app cache, and delete duplicates.

No ads. No paid subscriptions. No fake booster tools. Just clean and honest disk usage info.

---

## What It Does

* **Find large files:** Folders open instantly. Sizes update in the background so you see what is eating your storage.
* **App Diet:** See how much space apps like Spotify, YouTube, or web browsers use for their cache. Tap any app to open Android settings and clear its cache.
* **Find duplicates:** Spot copies of the same files across different folders. Choose if you want to match by file size, name, or timestamp.
* **Filter what you see:** Everything is shown by default. Turn off images to see only videos and other files in your camera folder, or search for files like `.pdf` or `.zip`.
* **Safe deleting:** Turn on selection mode, pick items with checkboxes, and see how much space you get back before deleting anything.
* **Zoom text:** Pinch with two fingers on the file list or use the menu slider to make text bigger or smaller.
* **Favorite folders:** Star any folder in selection mode to save it to your menu. Drag and drop folders in the menu to pick which one opens on app start.

---

## How It Is Different

Most phone cleaner apps show fake animations, pop up ads, or try to sell you monthly subscriptions.

FreeDataDiet is built differently:

* **No fake tools:** It does not pretend to boost your RAM or cool your CPU. It simply shows your real files and folders.
* **No ads or popups:** The app is completely quiet and ad-free.
* **You stay in control:** The app never deletes anything on its own. You pick what gets removed.
* **Fast and smooth:** Folders open right away without freezing your phone.

---

## Privacy and Trust

* **No internet access:** The app does not have internet permission. It cannot send your files, photos, or data anywhere.
* **No tracking:** There are no analytics, no accounts, and no background trackers.
* **Open source:** The full code is available under the MIT license for anyone to check.

---

## Permissions

FreeDataDiet only asks for two permissions:

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
