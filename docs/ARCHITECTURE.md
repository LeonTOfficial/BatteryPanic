# Architecture

Battery Panic is split by responsibility:

- `App`: application startup and coordination.
- `Battery`: battery status reading, polling, and pure alarm decision logic.
- `Overlay`: full-screen red warning windows, distinct Battery Panic alert layout, pulse speed, and pulse intensity.
- `MenuBar`: colored battery states, charging display, menu header, readable status summary, and commands.
- `Settings`: persisted settings, first-run onboarding, settings window, creator links, and launch-at-login support.
- `Sound`: built-in synthesized siren, repeated warning playback, sound catalog, selection, preview, and playback.
- `Shared`: constants, formatters, and small helpers.

The most important pure unit is `AlarmPolicy`. It decides whether the warning should be visible from a `BatteryStatus` and an `AlarmSettingsSnapshot`. UI classes call into that policy instead of duplicating threshold logic.

The preview button does not depend on the real current battery level. It creates a synthetic low-battery status, so the red overlay can always be tested immediately. Preview alarms are intentionally short and fixed at about four seconds.

The menu bar status is derived from `BatteryStatusAppearance`, which maps battery state into healthy, warning, critical, charging, or unavailable UI states.

The Settings window includes a lightweight `OverlayPreviewView` so pulse speed and intensity can be tuned without opening the full-screen overlay.
