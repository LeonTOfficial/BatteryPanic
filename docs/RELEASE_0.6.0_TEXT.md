# Battery Panic 0.6.0

Battery Panic 0.6.0 adds a native battery dashboard with real status data, a local seven-day history, and a clearer 30-minute alarm snooze.

## What's new

- Replaced the old settings-style menu content with a native battery dashboard.
- Shows the real percentage, battery or adapter state, remaining time when macOS reports it, and battery health.
- Stores no more than seven days of history locally, with 30-minute, one-hour, day, and week views.
- Shows the exact stored percentage and observation time on hover.
- Draws a smooth measured curve on a dynamically padded scale without fabricated battery samples.
- Colors only real charging intervals green and keeps adapter-without-charging periods distinct.
- Shows a robust average rate and short forecast only after enough uninterrupted real data exists.
- Pulses only the menu bar percentage during an active low-battery snooze; Reduce Motion uses a static red percentage.
- Removes the unused widget, App Group remnants, snapshot publisher, and fake 68% fallback.
- Includes runtime hardening and the vendored Sparkle 2.9.5 updater.

## Privacy

The battery history is stored locally in Application Support, retained for no more than seven days, and never sent to an analytics service or account.

## Download

Attach these files to this GitHub release:

- outputs/Battery.Panic.0.6.0.dmg
- outputs/Battery.Panic.0.6.0.zip

## Compatibility and installation

The current release package supports Apple silicon Macs (arm64) running macOS 13 or later.

1. Download Battery.Panic.0.6.0.dmg.
2. Drag Battery Panic into Applications.
3. Open Battery Panic from Applications.
4. If macOS blocks the first launch, open System Settings -> Privacy & Security and choose Open Anyway.

## Signing note

Battery Panic is open source and locally/ad-hoc signed. This build is not Apple-notarized, so macOS may show the normal first-launch warning for non-notarized apps. Sparkle verifies the EdDSA signature of update archives independently.

Website:
https://leontofficial.github.io/BatteryPanic/

Discord:
https://discord.gg/JPjrw3ft
