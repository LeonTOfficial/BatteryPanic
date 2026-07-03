# Battery Panic 0.5.11 Release Notes

Battery Panic 0.5.11 adds a helpful charging reminder and a stronger automatic critical mode for the last 2% of battery. The app still stays simple: one calm reminder while charging, one red warning system when the Mac is unplugged and running low.

## What's New

- Charging reminder:
  - New setting: **Remind me while charging**.
  - Default reminder threshold is **80%**.
  - Adjustable reminder threshold from **50% to 100%**.
  - Shows a short green/blue overlay when the Mac is plugged in and reaches the chosen percentage.
  - The reminder appears once per charging session, then resets after unplugging or dropping clearly below the threshold again.
  - The selected warning sound can play once for the charging reminder, but it does not loop.
- Critical 2% battery mode:
  - When unplugged at **2% or below**, Battery Panic switches the red overlay wording to **CRITICAL BATTERY**.
  - The critical state uses a stronger pulse and glow.
  - The warning sound continues looping until the critical low-battery alarm ends.
  - The menu status can show a more urgent critical alarm label.
- Settings updates:
  - Added a new **Charging reminder** section below the normal battery threshold.
  - The menu details now show both the low-battery alarm threshold and charging reminder threshold.
  - Existing overlay, sound, login, pause, and updater settings remain unchanged.
- Documentation updates:
  - README now explains the charging reminder, critical 2% mode, and the difference between a helpful battery-care hint and a guaranteed battery-health feature.
  - Release packaging has been moved to version 0.5.11.

## Build

```bash
./scripts/run_tests.sh
./scripts/build_app.sh
```

The local app bundle and release files are written to:

```text
outputs/Battery Panic.app
outputs/Battery.Panic.0.5.11.zip
outputs/Battery.Panic.0.5.11.dmg
```

## Distribution Note

The local build is ad-hoc signed. Upload the ZIP package for Sparkle/GitHub update testing and the DMG for normal drag-and-drop installation. For public downloadable releases beyond GitHub testing builds, use Developer ID signing and Apple notarization.
