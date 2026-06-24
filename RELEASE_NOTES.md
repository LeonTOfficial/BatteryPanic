# Battery Panic 0.3.0 Release Notes

Battery Panic 0.3.0 makes the app feel more original, clearer, and more useful during setup.

## What's New

- New red alert copy and layout:
  - Uses a more distinct Battery Panic style.
  - Avoids the previous "remaining" wording.
- Built-in synthesized Battery Panic Siren.
- Live Settings preview for pulse speed and pulse intensity.
- Configurable red-screen preview duration.
- Cleaner menu bar dropdown:
  - Better battery status readability.
  - Clear power connection state.
  - Threshold, alarm, overlay, and sound summary.
  - Duplicate top creator link removed.
- Modern menu bar battery states:
  - Green for healthy battery.
  - Orange when the battery is getting low.
  - Red with an exclamation mark when critical.
  - Charging state with a charging indicator.
- Security and quality pass:
  - No network behavior.
  - No secrets or tokens found in the repository scan.
  - Local-only privacy model documented.
  - Build and tests verified.

## Build

```bash
./scripts/run_tests.sh
./scripts/build_app.sh
```

The local app bundle is written to:

```text
outputs/Battery Panic.app
```

## Distribution Note

The local build is ad-hoc signed. For public downloadable releases outside GitHub source code, use Developer ID signing and Apple notarization.
