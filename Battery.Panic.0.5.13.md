# Battery Panic 0.5.13 Release Notes

Battery Panic 0.5.13 is a small visual hotfix for the red low-battery overlay.

## Highlights

### Overlay Alignment Fix

- Fixed the warning title position in the red overlay.
- Battery percentages such as `10%` and `20%` no longer crowd or overlap the battery icon.
- The fix applies to both real low-battery alerts and the Preview Alarm test.

### Cleaner Warning Card

- Added more spacing between the battery icon and the headline.
- Slightly reduced the headline size so the card keeps a balanced layout on different displays.
- Kept the existing red overlay style and behavior unchanged.

## Build

```bash
./scripts/run_tests.sh
./scripts/build_app.sh
```

The release files are written to:

```text
outputs/Battery Panic.app
outputs/Battery.Panic.0.5.13.zip
outputs/Battery.Panic.0.5.13.dmg
```

## Distribution Note

The local build is ad-hoc signed. Upload the ZIP package for Sparkle/GitHub update testing and the DMG for normal drag-and-drop installation.
