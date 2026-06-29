# Battery Panic

![Battery Panic redoverlay preview](docs/screenshots/overlay-preview.png)

Battery Panic is a native macOS menu bar app that makes low battery warnings impossible to miss. When your MacBook drops below your chosen battery threshold, Battery Panic shows a red pulsing screen overlay, plays an optional warning sound, and keeps the status visible in the menu bar.

The app is built with Swift and AppKit, stays local to your Mac, and is designed as a clean open-source project rather than a one-file demo.


## Download & Install

For normal users, use the direct app download below. Do **not** use the green **Code -> Download ZIP** button, because that downloads the source code, not the finished app.

**Latest app download:**

- [Download Battery Panic 0.5.5 DMG](https://github.com/LeonTOfficial/BatteryPanic/releases/download/v0.5.5/Battery.Panic.0.5.5.dmg) - recommended macOS drag-and-drop installer
- [Download Battery Panic 0.5.5 ZIP](https://github.com/LeonTOfficial/BatteryPanic/releases/download/v0.5.5/Battery.Panic.0.5.5.zip) - fallback if the DMG does not work

DMG install:

1. Download the DMG above.
2. Open the DMG.
3. Drag `Battery Panic.app` into **Applications**.
4. Open Battery Panic from **Applications**.

ZIP fallback:

1. Download the ZIP above.
2. Unzip it.
3. Move `Battery Panic.app` into **Applications**.
4. Open Battery Panic from **Applications**.

Battery Panic is currently open source and ad-hoc signed, but not notarized by Apple yet. macOS may show a message such as **“Battery Panic cannot be opened because the developer cannot be verified.”**

To open it without Terminal:

1. Click [Open Privacy & Security settings](x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension).
2. Scroll all the way down.
3. Find the message that Battery Panic was blocked.
4. Click **Open Anyway** / **Dennoch öffnen**.
5. Confirm **Open** if macOS asks again.

If the direct settings link does not open, open **System Settings -> Privacy & Security** manually and scroll to the bottom.

<img src="docs/screenshots/macos-privacy-security-open-anyway.jpg" alt="How to allow Battery Panic in Privacy & Security" width="560">

This happens because Battery Panic is not Apple-notarized yet. Removing this warning completely requires Apple Developer ID signing and notarization, which is planned for a later public distribution step.

See the full install guide: [`docs/INSTALL.md`](docs/INSTALL.md).

## Features

- Native macOS menu bar app.
- Green, orange, red, and charging-aware menu bar battery states.
- Red pulsing full-screen overlay across connected displays.
- Adjustable low-battery threshold.
- Adjustable overlay pulse speed and pulse intensity.
- Built-in continuous Battery Panic siren plus selectable macOS system warning sounds.
- Test buttons for both the red overlay and the selected sound.
- Live in-settings overlay preview that updates while you move pulse controls.
- Fixed short 4-second red-screen preview for safe testing.
- macOS WidgetKit extension with small, medium, and large Battery Panic widgets.
- Built-in Sparkle updater with a **Check for Updates...** menu item.
- Optional launch at login.
- First-run welcome/setup window.
- Privacy-friendly behavior: no analytics, no accounts, and network access only for optional Sparkle update checks.
- Custom app icon and README preview assets generated from source scripts.

## Screenshots

![Battery Panic status bar preview](docs/screenshots/status-bar-preview.png)
![Battery Panic settings preview](docs/screenshots/settings-preview.jpg)

## Usage

1. Open Battery Panic.
2. The first-run setup window appears.
3. Choose whether the app should start at login.
4. Click **Preview 4s Alarm** to test the visual warning.
5. Open **Settings** from the menu bar item to adjust threshold, overlay, and sound behavior.

Battery Panic only shows the real warning when the Mac has a battery, is unplugged, and the current percentage is at or below your configured threshold.

## Settings

- **Battery threshold:** default is 10%, adjustable from 1% to 50%.
- **Pulse red overlay:** enables or disables the animated overlay pulse.
- **Pulse speed:** controls how fast the warning breathes.
- **Pulse intensity:** controls how strong the red wash and glow are.
- **Warning sound:** choose the built-in Battery Panic Siren or macOS system sounds such as Basso, Ping, Glass, Hero, and more. During a real alarm, the selected sound loops until the alarm ends.
- **Test Sound:** plays the selected warning sound immediately.
- **Preview Red Screen / Preview 4s Alarm:** shows the overlay for about four seconds using a safe simulated low-battery state.
- **Start at login:** registers Battery Panic as a macOS login item.
- **Pause alarm:** temporarily disables real low-battery warnings. From the menu bar during an active alarm, pause is one-time and resets after the Mac is charging again or the battery returns above the threshold.

## Widgets

Battery Panic includes a WidgetKit extension for macOS. The widget shows your current battery percentage, warning state, threshold, and power connection status in a cleaner Battery Panic style.

For details, see [`docs/WIDGETS.md`](docs/WIDGETS.md).

## Updates

Battery Panic includes Sparkle update support. After installing a Sparkle-enabled version, users can choose **Check for Updates...** from the menu bar item instead of downloading every new version manually.

For release setup, see [`docs/UPDATES.md`](docs/UPDATES.md).

## Security and Privacy

Battery Panic is local-first:

- No analytics.
- No telemetry.
- No tracking.
- No account required.
- No network connection is needed for the battery warning itself.
- Optional update checks contact the configured Sparkle appcast on GitHub.
- No API keys or tokens.
- No private user data collection.

The app reads battery status through macOS power APIs and can optionally register itself as a login item. The red overlay appears only after login; macOS does not allow a normal app to draw over the lock screen or before the user session starts.

Read more in [`SECURITY.md`](SECURITY.md).

## macOS Compatibility

- Minimum supported macOS version: macOS 13.
- Tested in this workspace with Xcode 26.5 and Swift 6.3.2.
- Apple Silicon build output is generated by the local toolchain.

## Development

Run the focused logic tests:

```bash
chmod +x scripts/run_tests.sh
./scripts/run_tests.sh
```

Build the app:

```bash
./scripts/build_app.sh
```

The build script signs the app in a temporary staging folder, verifies it, then writes the local app bundle, GitHub-friendly ZIP package, and user-friendly DMG package into `outputs/`.

For publishing, release fields, and recommended GitHub security settings, see [`docs/GITHUB_RELEASE_GUIDE.md`](docs/GITHUB_RELEASE_GUIDE.md).

Open the project in Xcode:

```bash
open Package.swift
```

Use the `BatteryPanicApp` scheme for the app and `BatteryPanicWidgetExtension` for the widget source. More details: [`docs/XCODE.md`](docs/XCODE.md).

Generate the app icon and README screenshots:

```bash
swift scripts/create_icon.swift
swift scripts/create_readme_screenshots.swift
```

Project layout:

```text
Sources/BatteryPanicApp/
├── App/
├── Battery/
├── MenuBar/
├── Overlay/
├── Settings/
├── Shared/
├── Sound/
└── Widgets/
Sources/BatteryPanicWidgetExtension/
Sources/BatteryPanicWidgetShared/
```

## Credits

Created by Leon.

- GitHub: [LeonTOfficial](https://github.com/LeonTOfficial)
- Inspired by the clean, local-first project style used in [LeonAI](https://github.com/LeonTOfficial/LeonAI).

If Battery Panic helps you, I would be very happy about feedback or a GitHub star. It supports the project and motivates me to keep improving it.

## License

Battery Panic is released under the MIT License. See [`LICENSE`](LICENSE).

The MIT License requires that the copyright notice and permission notice stay included in copies or substantial portions of the software. In practice, that means redistributions of the source code should keep the attribution to Leon / LeonTOfficial.
