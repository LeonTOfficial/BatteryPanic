# Battery Panic 0.5.11 Release Notes

Battery Panic 0.5.11 adds a charging reminder, a stronger critical battery mode, and a few polish fixes before the public release.

## Highlights

### Charging Reminder

- New **Charging reminder** setting.
- Enabled by default at **80%**.
- Adjustable from **50% to 100%**.
- Shows a short green/blue overlay while the Mac is plugged in.
- Appears once per charging session and resets after unplugging or dropping clearly below the reminder level.
- The reminder sound plays once and does not loop.

### Critical 2% Mode

- At **2% or below** while unplugged, Battery Panic switches to **CRITICAL BATTERY** wording.
- The red overlay uses a stronger pulse and glow.
- The selected warning sound continues looping until the alarm ends.
- The menu status can show the more urgent critical state.

### Sound And Preview Fixes

- Apple system sounds such as Basso, Blow, Funk, Ping, and others now repeat reliably during looping alarms.
- Battery Panic Siren keeps its original one-shot preview sound.
- **Preview Red Screen** now always stops the overlay and sound after about four seconds.
- The selected warning sound preview in Settings now repeats briefly and stops automatically.
- Version History now opens the GitHub release page instead of the raw Markdown file.

### Visual Polish

- The charging reminder battery icon is aligned better at high percentages such as 100%.
- Charging reminder text is shorter and cleaner.
- Menu details show both the low-battery alarm threshold and the charging reminder threshold.

## Build

```bash
./scripts/run_tests.sh
./scripts/build_app.sh
```

The release files are written to:

```text
outputs/Battery Panic.app
outputs/Battery.Panic.0.5.11.zip
outputs/Battery.Panic.0.5.11.dmg
```

## Distribution Note

The local build is ad-hoc signed. Upload the ZIP package for Sparkle/GitHub update testing and the DMG for normal drag-and-drop installation.
