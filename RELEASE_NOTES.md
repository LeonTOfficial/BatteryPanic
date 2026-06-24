# Battery Panic 0.2.0 Release Notes

Battery Panic 0.2.0 turns the first version into a more polished macOS utility ready for public GitHub release.

## What's New

- Modern menu bar battery states:
  - Green for healthy battery.
  - Orange when the battery is getting low.
  - Red with an exclamation mark when critical.
  - Charging state with a charging indicator.
- Adjustable pulsing overlay:
  - Pulse speed setting.
  - Pulse intensity setting.
- Better audio warning alerts:
  - Select a macOS system sound.
  - Test the selected sound from Settings.
- Improved Preferences UI:
  - Clearer sections.
  - Better spacing.
  - More readable controls.
  - Creator and GitHub link.
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
