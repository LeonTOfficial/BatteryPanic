# Battery Panic 0.5.16

Battery Panic 0.5.16 fixes the vertically shifted text in every full-screen warning overlay.

## What's new

- Restored separate, balanced baselines for the mode label, warning title, and subtitle.
- Removed the crowded label/title spacing and the oversized gap above the subtitle.
- Corrected normal alarms, previews, critical mode, and charging reminders at both 80% and 100%.
- Added adaptive sizing and clipping so warning copy stays inside the card on compact displays.
- Kept clean per-frame redraws, so animated overlays remain free of duplicated or smeared text.
- Added rendered-pixel spacing checks at 1920x1080 and 1280x800.

## Download

Attach these files to this GitHub release:

- `outputs/Battery.Panic.0.5.16.dmg`
- `outputs/Battery.Panic.0.5.16.zip`

Recommended for normal users:

1. Download `Battery.Panic.0.5.16.dmg`.
2. Drag Battery Panic into Applications.
3. If macOS blocks the first launch, open System Settings -> Privacy & Security and click Open Anyway.

## Notes

Battery Panic is open source and locally/ad-hoc signed. It is not Apple-notarized yet, so macOS may show the normal first-launch security warning for non-notarized apps.

Website:
https://leontofficial.github.io/BatteryPanic/

Discord:
https://discord.gg/JPjrw3ft
