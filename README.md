# FreeDataDiet Mobile

[![Version: 1.3.0](https://img.shields.io/badge/version-1.3.0-blue.svg)]()
[![Platform: Android | Linux Mobile](https://img.shields.io/badge/Platform-Android%20%7C%20Linux%20Mobile-0078D6.svg)]()

> **Put your mobile storage on a diet.**  
> A fast, lightweight disk usage and app cache analyzer for Android and Linux Mobile.  
> *Find what is eating your phone's storage with no ads, no subscriptions, and zero nagware.*

---

## Features & Highlights

* **📁 Unified Storage Scope:**
  * Quickly switch between **Internal Storage** (`/storage/emulated/0`), **External MicroSD Cards / USB OTG**, or scan **All Storages** simultaneously.
  * Quick media presets for *Images*, *Videos*, *Audio*, and *Archives/APKs*.
* **⚡ App Diet (Cache & Footprint Cleaner):**
  * Displays all installed apps sorted by **Cache Size** or **Total Footprint**.
  * Instantly identifies apps like Spotify, Telegram, or YouTube consuming tens of gigabytes in cache.
  * **1-Tap Shortcut** directly to the native Android Storage screen to clear cache in one step.
* **🌲 Dual View Modes:**
  * **Folder Hierarchy Mode:** Interactive breadcrumb trail to navigate directories with live folder sizes and child counts.
  * **Recursive Flat View ("All Nested Files"):** Flattens all files under the current directory or across all drives into a single sorted list. Instantly surfaces the largest files even if buried 5 levels deep.
* **🔍 Live Search & Custom Filters:**
  * Filter visible files by name, or match custom extensions (e.g. `.pdf`, `.xmp`, `.log`, `.tmp`, or sidecar files).
* **🧬 Configurable Duplicate Detection:**
  * Spots duplicate copies across different folders and drives.
  * Choose matching criteria:
    * *Same Name & Same Size* (Default)
    * *Same Size Only* (Catches renamed duplicates)
    * *Same Name Only*
    * *Same Date & Time* (Invaluable for camera and photo syncs)
    * *Same Name, Size & Timestamp*
* **🗑️ Safe Batch Deletion Mode:**
  * Tap the checklist icon to toggle selection checkboxes.
  * Quickly select multiple files across folders.
  * Safe confirmation modal displaying the exact list of files and total reclaimed space (in MB/GB) before deletion.
* **🎨 Desktop-Aligned Aesthetic & Themes:**
  * Clean, high-contrast **Dark Mode** and **Bright Mode** with automatic OS theme following.
  * Desktop-consistent badges (`[DIR]`, `[FILE]`, `[SYS]`, `[LINK]`).
  * Proportional colored usage bars with configurable scaling (*Largest Item*, *Folder Total*, *Drive Capacity*).
  * Persistent user preferences saved locally.

---

## Required Android Permissions

1. **All Files Access (`MANAGE_EXTERNAL_STORAGE`):**
   * Required on Android 11+ to analyze storage folders (Downloads, DCIM, Documents, and external SD cards).
2. **Usage Access (`PACKAGE_USAGE_STATS`):**
   * Required for the **App Diet** view to read accurate APK, Data, and Cache byte statistics from Android's `StorageStatsManager`.

---

## Architecture & Performance

* **Non-Blocking Dart Isolates:** Disk scanning, directory summation, and duplicate clustering execute in true background OS threads, keeping the UI running at a locked 60/120 Hz.
* **Native Kotlin MethodChannel:** Direct interface to Android's `StorageManager` (multi-volume detection), `StorageStatsManager`, and `PackageManager`.
* **Zero Bloat:** No cloud telemetry, no analytics, and no background daemons.

---

## Building from Source

```bash
# Navigate to the project directory
cd FreeDataDietMobile

# Get dependencies
flutter pub get

# Run tests
flutter test

# Run on connected device / emulator
flutter run

# Build release APK
flutter build apk --release
```

---

## License

MIT License © 2026 LycosLane
