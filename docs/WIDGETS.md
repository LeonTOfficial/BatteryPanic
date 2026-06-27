# Battery Panic Widgets

Battery Panic includes a macOS WidgetKit extension with three widget sizes:

- Small: compact battery percentage and status.
- Medium: battery ring, status text, threshold, and power state.
- Large: dashboard-style Battery Panic panel.

The widget reads a small local battery snapshot written by the main app. It does not use accounts, analytics, telemetry, or network calls.

## How it is built

The repository is still a Swift Package based project. To keep the project clean, the widget is split into two targets:

```text
Sources/BatteryPanicWidgetShared/
Sources/BatteryPanicWidgetExtension/
```

The app writes widget data through:

```text
Sources/BatteryPanicApp/Widgets/WidgetSnapshotPublisher.swift
```

The release build embeds the extension into the app bundle:

```text
Battery Panic.app/Contents/PlugIns/BatteryPanicWidgetExtension.appex
```

## App Group

The app and widget use this App Group identifier:

```text
group.com.leontofficial.batterypanic
```

The entitlement templates are stored in:

```text
Entitlements/BatteryPanicApp.entitlements
Entitlements/BatteryPanicWidgetExtension.entitlements
```

For fully polished public distribution, the widget should later be signed with an Apple Developer account and a real App Group capability. The current local build is ad-hoc signed, which is suitable for local testing but not the same as a notarized Developer ID release.

## Build

```bash
swift build
./scripts/build_app.sh
```

After installing the app into Applications, open Battery Panic once. Then open macOS Notification Center / Edit Widgets and search for `Battery Panic`.
