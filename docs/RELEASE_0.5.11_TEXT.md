# Battery Panic 0.5.11

Battery Panic 0.5.11 adds charging reminders, a stronger critical battery mode, a redesigned project landing page, and final polish before the public release.

This update also includes feedback from one of the first Battery Panic users, who suggested a reminder when the Mac is charging and reaches a chosen percentage.

## Highlights

### Charging Reminder

- New charging reminder setting.
- Enabled by default at 80%.
- Adjustable from 50% to 100%.
- Shows a short green-blue overlay while the Mac is plugged in.
- Appears once per charging session.
- Plays a short one-time sound instead of looping.

### Critical 2% Mode

- At 2% or below while unplugged, Battery Panic switches to stronger critical wording.
- The red overlay uses a stronger pulse and glow.
- Apple system warning sounds repeat during the active alarm.
- Battery Panic Siren now keeps warning during a real alarm until the alert ends.

### Website And Release Polish

- New professional Battery Panic landing page.
- Styled version history page for Sparkle's Version History button.
- Improved download flow to avoid broken direct asset links before release assets are attached.
- Added Discord community link.
- Improved GitHub Actions checks for app builds, release packages, appcast, docs, and secret-looking values.

## Download

Attach these files to this GitHub release:

- `outputs/Battery.Panic.0.5.11.dmg`
- `outputs/Battery.Panic.0.5.11.zip`

Recommended for normal users:

1. Download `Battery.Panic.0.5.11.dmg`.
2. Drag Battery Panic into Applications.
3. If macOS blocks the first launch, open System Settings -> Privacy & Security and click Open Anyway.

## Notes

Battery Panic is open source and locally/ad-hoc signed. It is not Apple-notarized yet, so macOS may show the normal first-launch security warning for non-notarized apps.

Discord:
https://discord.gg/JPjrw3ft

Special thanks:
Thank you to Anni3 for early feedback and for suggesting a charging reminder when the Mac reaches a chosen percentage.
