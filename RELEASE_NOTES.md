# Battery Panic 0.4.0 Release Notes

Battery Panic 0.4.0 focuses on polish, stability, and a smoother first-run experience.

## What's New

- Cleaner Battery Panic icon:
  - More breathing room in the app icon.
  - Critical battery state no longer relies on a squeezed exclamation mark.
- Fixed Battery Panic Siren playback:
  - The generated sound now matches the Mac output audio format.
  - The siren can be tested from Settings.
- Continuous audio warnings:
  - A real low-battery alarm loops the selected sound while it remains active.
  - Preview alarms still play once and stop quickly.
- One-time alarm pause:
  - Pausing from the menu bar during an active alarm now silences only the current alarm state.
  - The pause resets automatically after charging starts or the battery goes back above the threshold.
- Short, predictable preview:
  - Red-screen previews now run for about four seconds from Welcome, Settings, and the menu bar.
- Smoother overlay:
  - Reduced redraw work for the pulsing red overlay.
  - Better behavior during longer tests and multi-display use.
- Improved welcome screen:
  - More spacing.
  - Clearer setup copy.
  - Personal note from Leon asking for feedback or a GitHub star.
- Modern menu bar battery states:
  - Green for healthy battery.
  - Orange when the battery is getting low.
  - Red when critical.
  - Charging state with a charging indicator.
- Security and quality pass:
  - No network behavior.
  - No secrets or tokens found in the repository scan.
  - Local-only privacy model documented.
  - Build and tests verified.
- WidgetKit preview:
  - Small, medium, and large Battery Panic widgets.
  - Local snapshot sharing from the menu bar app to the widget.
  - Widget extension embedded into the local app bundle by the build script.

## Build

```bash
./scripts/run_tests.sh
./scripts/build_app.sh
```

The local app bundle is written to:

```text
outputs/Battery Panic.app
outputs/Battery.Panic.0.4.0.zip
outputs/Battery.Panic.0.4.0.dmg
```

## Distribution Note

The local build is ad-hoc signed. Upload the zip package for GitHub testing releases. For public downloadable releases beyond GitHub source/testing builds, use Developer ID signing and Apple notarization.
