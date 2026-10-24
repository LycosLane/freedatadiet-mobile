# FreeDataDiet Mobile

[![Version: 1.6.2](https://img.shields.io/badge/version-1.6.2-blue.svg)](https://github.com/LycosLane/freedatadiet-mobile)
[![Platform: Android](https://img.shields.io/badge/Platform-Android%2010%2B-0078D6.svg)](https://github.com/LycosLane/freedatadiet-mobile)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Zero Telemetry](https://img.shields.io/badge/Telemetry-Zero-brightgreen.svg)]()
[![No Ads](https://img.shields.io/badge/Ads-None-success.svg)]()

> **Is your phone running out of space? Put your storage on a diet.**  
> Find what is actually taking up your storage, clear bloated app caches, and safely delete duplicate photos and videos.  
> **100% private. No ads. No subscriptions. No fake "RAM cleaner" scams.**

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

## What FreeDataDiet Does For You

Most "cleaner" apps on Android are loaded with intrusive ads, pushy subscriptions, and fake animations claiming to "boost your CPU".  
**FreeDataDiet is completely different**: it's an honest, transparent tool that puts you back in full control of your phone's storage.

### 🔍 1. See what is actually eating your storage
* **Visual size bars:** Big, clear bars immediately show you which folders are taking up gigabytes—no guessing or digging through endless menus.
* **Sort your way:** Tap column headers to sort instantly by largest files, newest or oldest downloads, or file names.
* **Nothing cut off:** Pinch to zoom in on smaller screens. File names wrap onto multiple lines so you always read the full name, not `my_vacation_video_202...`.

### ⚡ 2. Clear gigabytes of hidden app cache in seconds
* Apps like Instagram, TikTok, YouTube, Spotify, and Chrome quietly accumulate gigabytes of cached media that clog up your phone.
* The **App Diet** tab lists all your apps sorted from the biggest cache hog to the smallest.
* Tap any app to jump directly into Android's native system settings and wipe its cache with one tap.

### 👯 3. Find and remove duplicate photos and files
* Stop wasting space on identical pictures saved across WhatsApp, Downloads, and your Camera roll.
* **Preview before deleting:** Tap any picture to swipe through your files in full-screen with pinch-to-zoom, so you always know exactly what you are removing.
* **Side-by-side comparison:** Duplicates from subfolders are grouped together with their locations clearly shown. Use **"Keep 1st"** to safely select all redundant copies in one tap.
* **Smart Cleaning Assistant:** Deleting a duplicate from an old backup folder? The app automatically asks if you'd like to clean up other copies from the same folder.

### 👆 4. Select dozens of files with one finger
* No need to tap checkboxes one by one. Simply touch and drag your finger down the screen to select dozens of files or folders at once—just like in Google Photos.

### 🛡️ 5. Safe & foolproof
* **You can't break your phone:** Vital Android system folders and internal app data are locked and protected against deletion.
* **Zero surprises:** You see every file that will be deleted and confirm it yourself. No background deletions, ever.

---

## Why You Can Trust It: 100% Private & Transparent

* 🚫 **No Internet Permission:** The app does not even ask for `android.permission.INTERNET`. It is physically **impossible** for your personal photos, files, or device info to leave your phone.
* 🚫 **No Ads, No Subscriptions:** No banners, no unskippable video ads, no paywalls.
* 🚫 **Zero Tracking:** No analytics SDKs, no crash reporters phoning home, no user accounts.
* 🚫 **No Placebo Scams:** No fake "RAM boosters" or fraudulent "battery coolers". Only real files and honest tools.
* 📖 **Open Source:** 100% open-source software licensed under the MIT license. Read our [Privacy Policy](PRIVACY.md).

---

## Permissions Explained

To inspect storage and show app caches accurately, Android requires:

* **All Files Access (`MANAGE_EXTERNAL_STORAGE`):** Required on Android 11+ to calculate true folder sizes and allow you to delete unwanted files.
* **Usage Stats Access (`PACKAGE_USAGE_STATS`):** Used strictly to query installed app cache sizes from Android's system `StorageStatsManager`.
* **Query All Packages (`QUERY_ALL_PACKAGES`):** Needed on Android 11+ to display your installed apps in the App Diet tab.

---

## Build from Source

```bash
# Clone the repository
git clone https://github.com/LycosLane/freedatadiet-mobile.git
cd freedatadiet-mobile

# Get dependencies
flutter pub get

# Run automated tests
flutter test

# Run app on a connected device
flutter run
```

---

## Related Projects

* **[FreeDataDiet (Desktop)](https://github.com/LycosLane/freedatadiet):** High-speed disk space analyzer for Windows, Linux, and macOS written in Rust and egui.

---

## License

MIT License. Created and maintained by [LycosLane](https://github.com/LycosLane).
