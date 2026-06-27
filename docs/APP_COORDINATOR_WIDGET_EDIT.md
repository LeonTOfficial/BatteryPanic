# AppCoordinator edit for Battery Panic widgets

Add this small connection so the main Battery Panic app writes the newest battery status for the WidgetKit extension.

## 1. Add a property

In `Sources/BatteryPanicApp/App/AppCoordinator.swift`, near the other private properties, add:

```swift
private let widgetSnapshotPublisher = WidgetSnapshotPublisher()
```

## 2. Publish when battery status updates

Inside `handleBatteryStatus(_ status: BatteryStatus)`, after this line:

```swift
menuBarController.update(status: status)
```

add:

```swift
widgetSnapshotPublisher.publish(status: status, settings: settingsStore.snapshot())
```

So the block should roughly become:

```swift
latestStatus = status
menuBarController.update(status: status)
widgetSnapshotPublisher.publish(status: status, settings: settingsStore.snapshot())
evaluateAlarm(for: status)
```

## 3. Publish when settings change

Inside `handleSettingsChanged()`, replace the current logic with this version:

```swift
private func handleSettingsChanged() {
    menuBarController.updateSettings()
    guard let latestStatus else { return }

    widgetSnapshotPublisher.publish(status: latestStatus, settings: settingsStore.snapshot())
    evaluateAlarm(for: latestStatus)
}
```

That is all the main app needs.
