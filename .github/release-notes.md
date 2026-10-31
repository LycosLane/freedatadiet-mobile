FreeDataDiet Mobile 1.6.7 resolves file opening issues for PDF documents and audio files by replacing third-party intent dispatching with a native, permissionless Android Jetpack FileProvider implementation.

## What is New in 1.6.7

### Native FileProvider & Intent Handling
* **Fixed PDF Opening**: Resolved the `Couldn't find meta-data for provider with authority` error by switching to our official Jetpack FileProvider authority (`com.lycoslane.freedatadiet_mobile.fileProvider`).
* **Fixed Audio File Opening**: Resolved the `Permission denied: android.permission.READ_MEDIA_AUDIO` error when opening audiobooks or music files. The native implementation passes secure content URIs directly with `FLAG_GRANT_READ_URI_PERMISSION`, completely avoiding redundant scoped-storage permission prompts.
* **Zero Third-Party Intent Overhead**: Replaced the `open_filex` dependency with a robust, lightweight Kotlin platform bridge.
* **Secondary Storage Fallback**: Added safe fallback handling for documents and media on external micro-SD cards and USB OTG drives.

## Core Features
* **Disk Explorer**: Visual size bars, fast column sorting, pinch-to-zoom multiline filenames, and drag-to-select.
* **In-App Media Player**: Hardware-accelerated video playback with scrub controls and unified photo/video swiping.
* **App Diet**: Identify heavy app caches and clear them via native system settings.
* **Duplicate Cleaner**: Recursive subfolder grouping and two-pass SHA-256 duplicate detection.
* **100% Private**: Zero internet permissions requested, zero ads, zero analytics, and zero tracking.

## Installation
* Download `freedatadiet-mobile.apk` below.
* Open the APK on your phone to update.
