# Battery Panic WidgetKit setup

This pack adds a WidgetKit-ready design for Battery Panic with three widget sizes:

- Small widget: compact battery percentage and status.
- Medium widget: battery ring, status text, threshold and power state.
- Large widget: dashboard-style Battery Panic panel.

## Important reality check

A real macOS widget is not just a normal Swift file. It needs a WidgetKit Extension target in Xcode. The current Battery Panic repository is mainly a Swift Package executable app, so the widget source code is ready, but you still need to add the Widget Extension target in Xcode.

## Files in this pack

Copy these into the repository:

```text
Package.swift
Sources/BatteryPanicWidgetShared/BatteryPanicWidgetSnapshot.swift
Sources/BatteryPanicApp/Widgets/WidgetSnapshotPublisher.swift
Sources/BatteryPanicWidgetExtension/BatteryPanicWidgets.swift
docs/WIDGETS.md
docs/APP_COORDINATOR_WIDGET_EDIT.md
Entitlements/BatteryPanicApp.entitlements
Entitlements/BatteryPanicWidgetExtension.entitlements
```

## Xcode steps

1. Open the project/repository in Xcode.
2. Add a new Widget Extension target:
   - File -> New -> Target...
   - macOS -> Widget Extension
   - Product Name: `BatteryPanicWidgetExtension`
   - Do not include Live Activity.
3. Add `Sources/BatteryPanicWidgetExtension/BatteryPanicWidgets.swift` to the widget extension target.
4. Add the shared code target/package `BatteryPanicWidgetShared` to both:
   - the main app target
   - the widget extension target
5. Enable App Groups for both targets:
   - App Group: `group.com.leontofficial.batterypanic`
   - You can use the entitlement templates in the `Entitlements/` folder.
6. If your Bundle ID is different, you can change the app group string in:

```swift
BatteryPanicWidgetStorage.appGroupIdentifier
```

## Main app edit

Follow `docs/APP_COORDINATOR_WIDGET_EDIT.md`.

## Build test

After adding the Widget Extension target:

```bash
swift build
```

Then test the full app/widget in Xcode because WidgetKit extensions are built and embedded by Xcode, not by plain SwiftPM alone.

## Recommendation

For GitHub, commit the widget code first with a clear note that the actual WidgetKit extension target must be opened and built through Xcode.

Suggested commit:

```bash
git add Package.swift Sources docs
git commit -m "Add Battery Panic WidgetKit source"
git push origin main
```
