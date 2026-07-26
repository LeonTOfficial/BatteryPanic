# Battery Panic 0.5.15 Release Notes

Battery Panic 0.5.15 makes charging reminders session-aware and keeps every animated warning overlay crisp.

## Highlights

### Charging Reminder Startup Fix

- Charging reminders no longer appear immediately after launching Battery Panic or logging in when the battery is already at or above the configured threshold.
- A reminder is armed only after Battery Panic observes the battery below the threshold while plugged in.
- The reminder appears after the battery genuinely crosses the threshold during that same charging session.
- Existing once-per-session and unplug/reset behavior remains intact.

### Crisp Animated Overlays

- Every animation frame now clears the transparent drawing surface before rendering.
- Normal alarms, preview alarms, critical battery mode, and charging reminders use separate aligned text regions.
- Repeated frames no longer leave duplicated, smeared, or distorted text behind.
- Charging reminder copy stays readable at both 80% and 100%.

### Quality Checks

- Added startup and threshold-crossing tests for charging reminder session state.
- Added pixel-level rendering checks across normal, preview, critical, 80%, and 100% overlays.
- Verified logical image size, visible pixels, pulse-frame changes, and replacement of previous frames.

## Build

```bash
./scripts/run_tests.sh
./scripts/build_app.sh
```

The release files are written to:

```text
outputs/Battery Panic.app
outputs/Battery.Panic.0.5.15.zip
outputs/Battery.Panic.0.5.15.dmg
```

## Distribution Note

The free build is ad-hoc signed. Sparkle still verifies the EdDSA signature of every update archive. Upload the ZIP for Sparkle updates and the DMG for normal drag-and-drop installation.
