# Battery Panic 0.5.15

Battery Panic 0.5.15 fixes charging reminders at startup and keeps animated warning overlays crisp.

## What's new

- Charging reminders no longer appear immediately after app launch or login when the battery is already at or above the configured threshold.
- The charging reminder now waits for a real threshold crossing during the current plugged-in session.
- Animated overlays clear their transparent drawing surface before every frame.
- Normal alarms, previews, critical mode, and charging reminders use separately aligned text regions.
- New policy tests cover startup, arming, threshold crossing, and session resets.
- New pixel-level rendering tests cover normal, preview, critical, 80%, and 100% overlays.

## Download

Attach these files to this GitHub release:

- `outputs/Battery.Panic.0.5.15.dmg`
- `outputs/Battery.Panic.0.5.15.zip`

Recommended for normal users:

1. Download `Battery.Panic.0.5.15.dmg`.
2. Drag Battery Panic into Applications.
3. If macOS blocks the first launch, open System Settings -> Privacy & Security and click Open Anyway.

## Notes

Battery Panic is open source and locally/ad-hoc signed. It is not Apple-notarized yet, so macOS may show the normal first-launch security warning for non-notarized apps.

Website:
https://leontofficial.github.io/BatteryPanic/

Discord:
https://discord.gg/JPjrw3ft
