# Install Battery Panic

Battery Panic is meant to be installed like a normal macOS app. You do not need Terminal for the regular install flow.

## Recommended: Install with the DMG

1. Open [Battery Panic Releases](https://github.com/LeonTOfficial/BatteryPanic/releases) and download the attached `Battery.Panic.0.5.16.dmg` file when the release is published.
2. Open the downloaded DMG file.
3. Drag `Battery Panic.app` into the **Applications** shortcut.
4. Open Battery Panic from **Applications**.
5. If macOS blocks the first launch, use the `Open Privacy & Security` shortcut inside the DMG or the link below.

## Alternative: Install with the ZIP

Use this only if the DMG is not available.

1. Open [Battery Panic Releases](https://github.com/LeonTOfficial/BatteryPanic/releases) and download the attached `Battery.Panic.0.5.16.zip` file if you need the fallback package.
2. Unzip the file.
3. Move `Battery Panic.app` into **Applications**.
4. Open Battery Panic from **Applications**.

## Important: Releases vs Code ZIP

On GitHub, the green **Code -> Download ZIP** button downloads the source code. That is useful for developers, but it is not the easiest way to install the app.

For normal use, download Battery Panic through the direct links above or from **Releases**. Releases contain the ready-to-use `.dmg` and `.zip` app packages.

## If macOS Shows a Developer Warning

Battery Panic is open source and currently ad-hoc signed, but it is not notarized by Apple yet. Because of that, macOS may show a message such as:

```text
Battery Panic cannot be opened because the developer cannot be verified.
```

To open it without Terminal:

1. Click [Open Privacy & Security settings](x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension).
2. Scroll all the way down.
3. Find the message that Battery Panic was blocked.
4. Click **Open Anyway** / **Dennoch öffnen**.
5. Confirm **Open** if macOS asks again.

If the direct settings link does not open, use the manual path: **System Settings -> Privacy & Security**, then scroll to the bottom.

<img src="screenshots/macos-privacy-security-open-anyway.jpg" alt="How to allow Battery Panic in Privacy & Security" width="560">

This is the normal macOS flow for opening a non-notarized open-source app. The warning appears because Battery Panic has not yet been signed with an Apple Developer ID and notarized by Apple. Removing this warning completely requires an Apple Developer account and notarization, which costs money each year and is planned for a later public distribution step.

You can inspect the source code on GitHub before running the app.

## If the Menu Bar Icon Does Not Appear

If Battery Panic opens but you do not see its battery icon in the menu bar, macOS may have disabled the menu bar item:

1. Open **System Settings**.
2. Go to **Control Center -> Menu Bar**.
3. Find **Battery Panic**.
4. Turn the switch on.

Battery Panic can still be running while this switch is off, but macOS will hide the menu bar icon until you enable it again.

## Uninstall

1. Quit Battery Panic from the menu bar.
2. Delete `Battery Panic.app` from **Applications**.

Battery Panic does not require an account, analytics service, or telemetry service. The battery warning works locally; optional update checks use Sparkle and contact the configured GitHub appcast URL.
