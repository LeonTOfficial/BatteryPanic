# Battery Panic 0.5.12 Release Notes

Battery Panic 0.5.12 is a polish and stability update for the macOS app, installer, and Sparkle update experience.

## Highlights

### Menu Bar Polish

- Improved the battery icon drawing used in the macOS menu bar.
- Improved the larger battery icon in the Battery Panic dropdown header.
- The icon now keeps a cleaner battery shape instead of looking squeezed or distorted.

### Welcome And Settings Fixes

- Enlarged the three first-launch setup tiles for better spacing and readability.
- Settings now opens at the top every time, even if it was previously scrolled to the bottom.
- This makes the first-run flow cleaner when users open Settings from the welcome window.

### Version History Polish

- Reworked the Sparkle release notes page shown from Version History.
- The page now uses Battery Panic styling, clearer release highlights, and less empty space.
- The release notes remain lightweight so they load quickly inside Sparkle.

### Release Packaging

- Improved the styled DMG packaging settings so the release DMG builds more reliably.
- Rebuilt and verified the ZIP and DMG release files.

## Build

```bash
./scripts/run_tests.sh
./scripts/build_app.sh
```

The release files are written to:

```text
outputs/Battery Panic.app
outputs/Battery.Panic.0.5.12.zip
outputs/Battery.Panic.0.5.12.dmg
```

## Distribution Note

The local build is ad-hoc signed. Upload the ZIP package for Sparkle/GitHub update testing and the DMG for normal drag-and-drop installation.
