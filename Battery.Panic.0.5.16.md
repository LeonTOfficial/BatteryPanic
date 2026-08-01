# Battery Panic 0.5.16 Release Notes

Battery Panic 0.5.16 restores the intended text alignment in every full-screen alarm overlay.

## Highlights

### Correct Alarm Layout

- The mode label, warning title, and subtitle again use stable, separate vertical baselines.
- The warning title no longer crowds the mode label.
- The subtitle no longer sits far below the title.
- Normal alarms, preview alarms, critical mode, and 80% or 100% charging reminders share the corrected layout.

### Compact Display Safety

- Warning text scales down only when needed to stay inside the card.
- Drawing is clipped to the text region so long copy cannot overlap the icon or card edge.
- Per-frame surface clearing from 0.5.15 remains in place, preventing duplicated or smeared animation frames.

### Quality Checks

- Added pixel-band checks that measure the visible gaps between all three text lines.
- Covered normal, preview, critical, 80%, and 100% overlays at both 1920x1080 and 1280x800.
- Kept startup-session policy, pulse-frame replacement, image-size, and menu bar icon coverage.

## Build

```bash
./scripts/run_tests.sh
./scripts/build_app.sh
```

The release files are written to:

```text
outputs/Battery Panic.app
outputs/Battery.Panic.0.5.16.zip
outputs/Battery.Panic.0.5.16.dmg
```

## Distribution Note

The free build is ad-hoc signed. Sparkle still verifies the EdDSA signature of every update archive. Upload the ZIP for Sparkle updates and the DMG for normal drag-and-drop installation.
