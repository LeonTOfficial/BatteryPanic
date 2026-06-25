# Install Battery Panic

Battery Panic is meant to be installed like a normal macOS app. You do not need Terminal for the regular install flow.

## Recommended: Install with the DMG

1. Download [Battery Panic 0.4.0.dmg](https://github.com/LeonTOfficial/BatteryPanic/releases/download/v0.4.0/Battery%20Panic%200.4.0.dmg).
2. Open the downloaded DMG file.
3. Drag `Battery Panic.app` into the **Applications** shortcut.
4. Open Battery Panic from **Applications**.

## Alternative: Install with the ZIP

Use this only if the DMG is not available.

1. Download [Battery Panic 0.4.0.zip](https://github.com/LeonTOfficial/BatteryPanic/releases/download/v0.4.0/Battery%20Panic%200.4.0.zip).
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

To open the app without Terminal:

1. Open **Applications** in Finder.
2. Right-click `Battery Panic.app`.
3. Click **Open**.
4. Confirm **Open**.

This is the normal macOS flow for opening a non-notarized open-source app. You can inspect the source code on GitHub before running it.

## Uninstall

1. Quit Battery Panic from the menu bar.
2. Delete `Battery Panic.app` from **Applications**.

Battery Panic does not require an account, analytics service, telemetry service, or network connection.
