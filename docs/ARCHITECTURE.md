# Architecture

Battery Panic is split by responsibility:

- `App`: application startup and coordination.
- `Battery`: battery status reading, polling, and pure alarm decision logic.
- `Overlay`: full-screen red warning windows, distinct Battery Panic alert layout, pulse speed, and pulse intensity.
- `MenuBar`: colored battery states, charging display, menu header, readable status summary, and commands.
- `Settings`: persisted settings, first-run onboarding, settings window, creator links, and launch-at-login support.
- `Sound`: built-in synthesized siren, repeating Apple system warning playback, sound catalog, selection, preview, and playback.
- `Shared`: constants, formatters, and small helpers.
- `Updates`: Sparkle updater integration and menu item wiring.

The most important pure unit is `AlarmPolicy`. It decides whether the warning should be visible from a `BatteryStatus` and an `AlarmSettingsSnapshot`. UI classes call into that policy instead of duplicating threshold logic.

The preview button does not depend on the real current battery level. It creates a synthetic low-battery status, so the red overlay can always be tested immediately. Preview alarms are intentionally short and fixed at about four seconds.

Menu bar pause is intentionally one-time while a real alarm is active. It silences the current low-battery state and resets once the alarm condition clears, so the user does not accidentally disable future warnings forever.

The menu bar status is derived from `BatteryStatusAppearance`, which maps battery state into healthy, warning, critical, charging, or unavailable UI states.

The Settings window includes a lightweight `OverlayPreviewView` so pulse speed and intensity can be tuned without opening the full-screen overlay.

Battery Panic ships only as a menu bar app. There is no WidgetKit extension,
App Group, or `.appex` embedded in the application bundle.

Sparkle is vendored as a local XCFramework under `Vendor/Sparkle` so Xcode, local builds, and CI do not depend on SwiftPM downloading a binary artifact during every setup.
