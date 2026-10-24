# FreeDataDiet Mobile

[![Version: 1.4.0](https://img.shields.io/badge/version-1.4.0-blue.svg)](https://github.com/LycosLane)
[![Platform: Android | Linux Mobile](https://img.shields.io/badge/Platform-Android%20%7C%20Linux%20Mobile-0078D6.svg)](https://github.com/LycosLane)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Zero Telemetry](https://img.shields.io/badge/Telemetry-Zero-brightgreen.svg)]()
[![No Ads](https://img.shields.io/badge/Ads-None-success.svg)]()

> **Put your storage on a diet — with total control, zero ads, and no gimmicks.**  
> FreeDataDiet Mobile is an open, transparent, and lightning-fast disk usage and app cache analyzer for Android and Linux Mobile.

---

## What is FreeDataDiet?

FreeDataDiet Mobile is a diagnostic storage manager that shows you **exactly what is taking up space on your phone, SD cards, and USB drives** — down to the exact byte. 

Built as the mobile companion to the FreeDataDiet desktop suite, it brings the precision and clarity of a desktop file manager to your pocket. There are no progress spinners blocking your screen, no aggressive cleaner popups, and no mysterious "junk score" numbers. Just clear, honest data about your files and apps.

---

## What can you use it for?

* **Find storage hogs in seconds:** Spot gigantic video files, forgotten downloads, or hidden game resources buried deep in nested folders.
* **Stop app cache bloat (App Diet):** See which streaming apps, social networks, and browsers are quietly hoarding 10 GB to 30 GB of cached data, with a direct 1-tap shortcut to native Android storage settings to wipe cache safely.
* **Track down duplicate files:** Find redundant copies scattered across internal storage, camera syncs, and external backups using custom rules (matching size, name, or exact timestamp).
* **Target custom file types:** Instantly isolate `.pdf` documents, orphaned RAW images (`.dng`, `.cr2`), sidecar files (`.xmp`), archives (`.zip`, `.apk`), or temporary logs.
* **Reclaim space safely:** Mark multiple items for deletion with real-time reclaimed byte counting and an explicit confirmation list before a single file is touched.

---

## Why is it different?

Most mobile "cleaner" apps are filled with deceptive gimmicks: fake "RAM booster" animations, intrusive ads, paid subscriptions, and fear-mongering warnings.

FreeDataDiet takes the opposite approach:

| Traditional "Cleaner" Apps | FreeDataDiet Mobile |
| :--- | :--- |
| **Fake Optimizations:** Placebo animations claiming to "cool down CPU" or "clean RAM". | **Honest Reality:** Android manages RAM automatically. We focus purely on real files and real storage. |
| **Ad-Ridden & Annoying:** Full-screen popups, video ads, and constant nag notifications. | **100% Ad-Free:** Zero ads, zero prompts, zero subscriptions. Completely quiet. |
| **Black-Box Deletions:** One-click "Clean" buttons that wipe things without showing you what's deleted. | **Complete Transparency:** You see the exact filename, path, date, and byte size. Nothing is deleted unless you explicitly select it. |
| **Sluggish UI:** Blocks the screen while scanning millions of files. | **Instant Shallow Listing:** Folders open in under 5 milliseconds. Background threads calculate sizes progressively in real time without freezing the UI. |
| **Desktop-Class Controls:** Barebones lists with fixed font sizes. | **Interactive Table View:** Clickable column headers (Sort by Name, Date, or Size), fluid two-finger pinch-to-zoom, and custom font scaling. |

---

## Why can you trust this?

* **Zero Internet Access:** FreeDataDiet does not even request the Android `INTERNET` permission in its manifest. It cannot send your files, metadata, or browsing history anywhere, because it has no network code.
* **Zero Telemetry or Analytics:** No Firebase, no Google Analytics, no crash loggers, and no third-party tracking SDKs. What happens on your device stays strictly on your device.
* **Fully Open Source:** Every line of code is open under the MIT License. Anyone can audit the source code, verify permissions, or build the app independently.
* **Native System Bridges:** Integrates directly with Android's official `StorageStatsManager` and `StorageManager` to report genuine hardware-accurate figures.

---

## Key Capabilities

### 1. High-Performance Disk Browser
* **Immediate Access:** Tap any folder and see its contents immediately. Subdirectory sizes stream in progressively in the background without UI lag.
* **Desktop Table Sorting:** Tap column headers to cycle sorting:
  * **Name:** A → Z or Z → A
  * **Date:** Newest first or Oldest first
  * **Size:** Largest items first (calculating folders automatically prioritized on top)
* **Pinch-to-Zoom & Scalable UI:** Adjust text size with fluid two-finger pinch gestures on the table, or use the zoom slider in the menu (80% to 160%). Your scale preference is saved across app launches.
* **Proportional Usage Bars:** Color-graded bars visually indicate the relative weight of each folder or file at a glance.

### 2. App Diet (Cache & Footprint Inspector)
* Inspect the true storage footprint of every installed app, split into **Code Size (APK)**, **User Data**, and **Cache**.
* Sort apps by largest cache or largest total footprint.
* Dedicated toggle to show or hide pre-installed system apps.
* 1-tap shortcut straight into Android's native App Info screen to clear cache or uninstall bloatware without leaving the app.

### 3. Smart Duplicate Spotter
* Configurable matching rules:
  * **Match File Size** (catches identical files even if renamed)
  * **Match File Name**
  * **Match Exact Timestamp** (ideal for camera photo syncs)
* Clear duplicate group badges (`DUP #1`, `DUP #2`) make it immediately obvious which files are copies of each other.
* One-tap filter to hide all unique files and show duplicates exclusively.

### 4. Unified Filter & Preference Sheet
* Clean, centralized menu with uniform controls:
  * **Live Search & Extension Filter:** Type `.pdf`, `.mp4`, `backup`, `sidecar`, etc.
  * **Quick Media Categories:** Images, Videos, Audio, Documents, Archives & APKs.
  * **Scope Control:** Toggle *Include subfolders* to flatten deep folder trees into a single list.
  * **Appearance:** Dark Mode, Bright Mode, or follow System Theme.

### 5. Scan Locations & Quick Favorites
* Top bar location selector strictly organized by scan targets:
  * Internal Flash Storage
  * External MicroSD Cards & USB OTG drives
  * All Storages (merged view)
  * Quick-access bookmarked folders (Downloads, Documents, DCIM, or custom folders)
* Bookmark any folder with the star icon (`★`) in the breadcrumb trail and choose your default startup folder for instant access on launch.

---

## Required Permissions Explained

FreeDataDiet requests only the permissions strictly required to perform its job:

| Permission | Why It Is Needed |
| :--- | :--- |
| **All Files Access (`MANAGE_EXTERNAL_STORAGE`)** | Required on Android 11+ so the analyzer can inspect folder structures and measure file sizes across user storage, SD cards, and USB drives. |
| **Usage Stats (`PACKAGE_USAGE_STATS`)** | Required by the **App Diet** screen to query Android's `StorageStatsManager` for accurate APK, user data, and cache byte counts. |

> [!NOTE]
> FreeDataDiet does **not** request the `INTERNET` permission. Your data never leaves your device.

---

## Building from Source

FreeDataDiet is built with Flutter and Kotlin. To build the project locally:

```bash
# Clone the repository
git clone https://github.com/LycosLane/FreeDataDietMobile.git
cd FreeDataDietMobile

# Fetch dependencies
flutter pub get

# Run test suite
flutter test

# Run on a connected Android phone or emulator
flutter run

# Compile an optimized release APK
flutter build apk --release
```

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.  
Maintained by [LycosLane](https://github.com/LycosLane).
