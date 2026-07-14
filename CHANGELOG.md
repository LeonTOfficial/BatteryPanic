# Changelog

## 0.5.12

- Improved the menu bar and menu header battery icon rendering so the battery shape looks less squeezed.
- Enlarged the first-launch welcome setup tiles for better spacing and readability.
- Fixed Settings opening at the previous scroll position; it now starts at the top when opened.
- Reworked the Sparkle release notes page used by Version History.
- Increased the styled DMG staging size so release DMG packaging completes reliably.

## 0.5.11

- Added a charging reminder that appears once per charging session when the Mac reaches the configured charging percentage.
- Added charging reminder settings with an enabled toggle and an adjustable 50% to 100% threshold, defaulting to 80%.
- Added automatic critical battery mode at 2% or below with stronger red overlay wording and pulse intensity.
- Added logic tests for charging reminders, session reset behavior, and critical low-battery mode.
- Updated README, release notes, appcast, and release package versions.

## 0.4.0

- Reworked the app and menu bar icon so the critical state is cleaner and no longer uses a squeezed exclamation mark.
- Fixed Battery Panic Siren playback by matching the generated audio buffer to the Mac output format.
- Added repeated playback for Apple system warning sounds while a real low-battery alarm remains active.
- Made all red-screen previews a fixed short 4-second test.
- Improved the first-run welcome screen with more spacing and a personal note from Leon.
- Reduced overlay drawing work to keep the pulsing warning smoother over time.
- Updated README previews, release notes, and local app bundle version.

## 0.3.0

- Redesigned the red warning overlay copy and layout to feel more distinct and ownable.
- Added a built-in synthesized Battery Panic Siren sound.
- Added live pulsing overlay preview inside Settings.
- Improved the menu bar dropdown with a more readable status/settings summary.
- Removed the duplicate creator link from the top menu header while keeping credits lower in the menu.

## 0.2.0

- Added adjustable pulse speed and pulse intensity settings.
- Added selectable macOS warning sounds and a Test Sound button.
- Added modern green, orange, red, and charging menu bar states.
- Added a richer menu bar dropdown with creator and GitHub links.
- Improved Settings spacing, sections, readability, and controls.
- Added README screenshot preview assets.
- Expanded README, SECURITY, CONTRIBUTING, and release documentation.
- Fixed the red overlay preview crash with a safer AppKit window initialization path.
- Ran a local security and secret scan before release prep.

## 0.1.0

- Initial Battery Panic app.
- Added menu bar app shell, battery monitoring, red pulsing overlay, settings window, warning sound, launch-at-login toggle, tests, and local app build script.
