# FreeDataDiet Brand Guidelines

## Core Identity

FreeDataDiet uses the White Fedora as its official mark. The symbol represents transparent, ethical, zero-bloat open source software. It pairs a high-contrast white crown and brim with a modular two-tone ribbon.

The mark is identical across all platforms: Android mobile, Windows, Linux, and macOS desktop.

## Logo Geometry

The logo is built from pure flat geometric vector shapes:
- **Angle**: A dynamic -6 degree upward tilt.
- **Crown**: Crisp white silhouette with a negative-space V-pinch at the top.
- **Negative Space Gap**: A clean horizontal cut separating the crown from the ribbon, showing the background directly.
- **Modular Ribbon**: Two color blocks separated by negative space:
  - Left segment (Cyan `#00B4FF`): Symbolizes clean data, active directories, and healthy storage.
  - Right segment (Amber `#FFB020`): Symbolizes the storage diet, bloat, and cache optimization.
- **Brim**: Bold, sweeping white curve running across the base of the mark.

## Color Palette

### Primary Brand Colors

| Swatch | Name | Hex | RGB | Usage |
|---|---|---|---|---|
| Obsidian Dark | Dark Background | `#101216` | `16, 18, 22` | Dark mode background, icon background |
| Crisp Light | Light Background | `#F8FAFC` | `248, 250, 252` | Bright mode background |
| Pure White | Mark White | `#FFFFFF` | `255, 255, 255` | Hat crown, brim, high-contrast dark mode text |
| Brand Cyan | Storage Cyan | `#00B4FF` | `0, 180, 255` | Primary highlight, directory indicators, healthy data bar |
| Brand Amber | Diet Orange | `#FFB020` | `255, 176, 32` | Secondary highlight, cache badges, storage diet warnings |

### Surface and UI Hierarchy

#### Dark Theme
- Scaffold Background: `#101216`
- Surface / App Bar: `#171A21`
- Card / Container: `#1E222B`
- Border / Divider: `#2B313E`
- Primary Text: `#ECEFF4`
- Secondary Text: `#94A3B8`

#### Light Theme
- Scaffold Background: `#F8FAFC`
- Surface / App Bar: `#FFFFFF`
- Card / Container: `#FFFFFF`
- Border / Divider: `#E2E8F0`
- Primary Text: `#0F172A`
- Secondary Text: `#64748B`

## Modular Ribbon System

The White Fedora mark serves as the universal anchor for the open source software suite. Different applications customize only the ribbon colors:

- **FreeDataDiet**: Cyan (`#00B4FF`) and Amber (`#FFB020`)
- **FreeWinly**: Windows Blue (`#0078D4`) and Cyan (`#00B4FF`)
- **Alltimer**: Deep Indigo (`#6366F1`) and Purple (`#A855F7`)

## Icon Specifications and Safe Zones

### Android Adaptive Icons
- Canvas size: 108dp x 108dp.
- Foreground safe zone: 72dp diameter circle centered on the canvas.
- The fedora mark is scaled to fit within the 72dp boundary with margin so no part of the brim is clipped by manufacturer masks (circle, squircle, pebble, or rounded rectangle).
- Background: Solid Obsidian `#101216`.

### Desktop and Store Assets
- Vector Master: `assets/icons/freedatadiet.svg` (512x512 viewBox)
- Hi-Res App Icon: `assets/icons/app_icon.png` (512x512, 32-bit PNG)
- Windows Icon: `assets/icons/freedatadiet.ico` (multi-resolution 16, 32, 48, 64, 128, 256 px)
- Android Play Store: `android/app/src/main/playstore-icon.png` (512x512)

## Usage Rules
- Do not add 3D bevels, glossy reflections, or drop shadows to the hat vector.
- Maintain the -6 degree slant. Do not rotate arbitrarily.
- Keep the negative-space pinch and band gap transparent.
