# Battery Panic 0.5.4 Release Notes

Battery Panic 0.5.4 fixes a startup visibility issue that could make Battery Panic appear to do nothing after launch.

## What's New

- Fixed the normal macOS app launch path:
  - Battery Panic no longer appears to do nothing after opening from Finder or Applications.
  - The Settings window is shown after launch so users can see that the app is running.
- Removed launch-time blocking work:
  - Battery status polling no longer blocks the main app startup.
  - Widget snapshot updates now run in the background instead of freezing the UI.
  - The live overlay preview starts after the Settings window is visible.
- Cleaner Battery Panic icon:
  - More breathing room in the app icon.
  - Critical battery state no longer relies on a squeezed exclamation mark.
- Fixed Battery Panic Siren playback:
  - The generated sound now matches the Mac output audio format.
  - The siren can be tested from Settings.
- Continuous audio warnings:
  - A real low-battery alarm loops the selected sound while it remains active.
  - Preview alarms still play once and stop quickly.
- Temporary alarm pause:
  - Pausing from the menu bar now silences alarms temporarily for 30 minutes.
  - The alarm turns back on automatically after the pause expires.
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
  - No analytics, telemetry, tracking, accounts, or private data collection.
  - Network use is limited to optional Sparkle update checks.
  - No secrets or tokens found in the repository scan.
  - Privacy model documented.
  - Build and tests verified.
- WidgetKit preview:
  - Small, medium, and large Battery Panic widgets.
  - Local snapshot sharing from the menu bar app to the widget.
  - Widget extension embedded into the local app bundle by the build script.
- Sparkle updater:
  - Adds a menu bar **Check for Updates...** item.
  - Prepares signed GitHub release updates through `appcast.xml`.
  - Keeps the private Sparkle signing key out of the repository.

## Build

```bash
./scripts/run_tests.sh
./scripts/build_app.sh
```

The local app bundle is written to:

```text
outputs/Battery Panic.app
outputs/Battery.Panic.0.5.4.zip
outputs/Battery.Panic.0.5.4.dmg
```

## Distribution Note

The local build is ad-hoc signed. Upload the zip package for GitHub testing releases. For public downloadable releases beyond GitHub source/testing builds, use Developer ID signing and Apple notarization.
