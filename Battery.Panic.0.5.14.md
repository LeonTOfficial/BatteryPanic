# Battery Panic 0.5.14 Release Notes

Battery Panic 0.5.14 improves the menu bar battery icon and makes secure background updates more automatic.

## Highlights

### Clearer Battery Icon

- Rebuilt the icon with uniform geometry so it stays proportional in the menu bar and menu header.
- Battery fill now accurately reflects 0% through 100%.
- Added clean empty, full, charging, and critical states.
- Kept one clear charging bolt beside the compact menu bar icon instead of crowding the battery shape.

### Safer Automatic Updates

- Updated the bundled Sparkle framework from 2.9.3 to 2.9.4.
- Enabled signed update downloads and background installation by default when macOS permissions allow it.
- Kept manual **Check for Updates...** available.
- Moved the launch check onto Sparkle's recommended startup lifecycle.
- Disabled Sparkle system profiling and added privacy-safe update error logging.

### Quality Checks

- Added geometry tests for empty, half-full, full, clamped, and scaled battery states.
- Added pixel-level checks for visible outlines, battery fill, and the charging bolt.
- Verified the app, embedded widget, Sparkle framework, ZIP, DMG, and code signatures.

## Build

```bash
./scripts/run_tests.sh
./scripts/build_app.sh
```

The release files are written to:

```text
outputs/Battery Panic.app
outputs/Battery.Panic.0.5.14.zip
outputs/Battery.Panic.0.5.14.dmg
```

## Distribution Note

The free build is ad-hoc signed. Sparkle still verifies the EdDSA signature of every update archive. Upload the ZIP for Sparkle updates and the DMG for normal drag-and-drop installation.
