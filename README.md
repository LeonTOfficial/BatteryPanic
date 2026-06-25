# Battery Panic

![Battery Panic redoverlay preview](docs/screenshots/overlay-preview.png)

Battery Panic is a native macOS menu bar app that makes low battery warnings impossible to miss. When your MacBook drops below your chosen battery threshold, Battery Panic shows a red pulsing screen overlay, plays an optional warning sound, and keeps the status visible in the menu bar.

The app is built with Swift and AppKit, stays local to your Mac, and is designed as a clean open-source project rather than a one-file demo.


## Download & Install

For normal users, use the direct app download below. Do **not** use the green **Code -> Download ZIP** button, because that downloads the source code, not the finished app.

**Latest app download:**

- [Download Battery Panic 0.4.0 DMG](https://github.com/LeonTOfficial/BatteryPanic/releases/download/v0.4.0/Battery.Panic.0.4.0.dmg) - recommended macOS drag-and-drop installer
- [Download Battery Panic 0.4.0 ZIP](https://github.com/LeonTOfficial/BatteryPanic/releases/download/v0.4.0/Battery.Panic.0.4.0.zip) - fallback if the DMG does not work

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

Try this first:

1. Right-click `Battery Panic.app` in **Applications**.
2. Choose **Open**.
3. Confirm **Open**.

If that does not work, open [Privacy & Security settings](x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension), scroll down, find the Battery Panic security message, and click **Open Anyway** / **Dennoch öffnen**. If the link does not open System Settings, open **System Settings -> Privacy & Security** manually and scroll to the bottom.

This happens because Battery Panic is not Apple-notarized yet. Removing this warning completely requires Apple Developer ID signing and notarization, which is planned for a later public distribution step.

See the full install guide: [`docs/INSTALL.md`](docs/INSTALL.md).

## Features

- Native macOS menu bar app.
- Green, orange, red, and charging-aware menu bar battery states.
- Red pulsing full-screen overlay across connected displays.
- Adjustable low-battery threshold.
- Adjustable overlay pulse speed and pulse intensity.
- Built-in repeating Battery Panic siren plus selectable macOS system warning sounds.
- Test buttons for both the red overlay and the selected sound.
- Live in-settings overlay preview that updates while you move pulse controls.
- Fixed short 4-second red-screen preview for safe testing.
- Optional launch at login.
- First-run welcome/setup window.
- Local-only behavior: no analytics, no network calls, no accounts.
- Custom app icon and README preview assets generated from source scripts.

## Screenshots

![Battery Panic status bar preview](docs/screenshots/status-bar-preview.png)
![Battery Panic settings preview](docs/screenshots/settings-preview.png)

## Installation

Normal users should install from the [latest GitHub Release](https://github.com/LeonTOfficial/BatteryPanic/releases/latest). Download the DMG if available, open it, and drag `Battery Panic.app` into **Applications**.

Developers can build locally with:

```bash
chmod +x scripts/build_app.sh
./scripts/build_app.sh
```

The finished local packages are created at:

```text
outputs/Battery Panic.app
outputs/Battery Panic 0.4.0.zip
outputs/Battery Panic 0.4.0.dmg
```

Open `Package.swift` in Xcode if you want to run the Swift package directly. Select the `BatteryPanicApp` scheme, choose **My Mac**, and press Run.

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
- **Warning sound:** choose the built-in Battery Panic Siren or macOS system sounds such as Basso, Ping, Glass, Hero, and more.
- **Test Sound:** plays the selected warning sound immediately.
- **Preview Red Screen / Preview 4s Alarm:** shows the overlay for about four seconds using a safe simulated low-battery state.
- **Start at login:** registers Battery Panic as a macOS login item.
- **Pause alarm:** temporarily disables real low-battery warnings.

## Security and Privacy

Battery Panic is local-first:

- No analytics.
- No telemetry.
- No tracking.
- No account required.
- No network connection needed.
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
└── Sound/
```

## Credits

Created by Leon.

- GitHub: [LeonTOfficial](https://github.com/LeonTOfficial)
- Inspired by the clean, local-first project style used in [LeonAI](https://github.com/LeonTOfficial/LeonAI).

If Battery Panic helps you, I would be very happy about feedback or a GitHub star. It supports the project and motivates me to keep improving it.

## License

Battery Panic is released under the MIT License. See [`LICENSE`](LICENSE).

The MIT License requires that the copyright notice and permission notice stay included in copies or substantial portions of the software. In practice, that means redistributions of the source code should keep the attribution to Leon / LeonTOfficial.
