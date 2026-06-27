import Foundation
import WidgetKit
import BatteryPanicWidgetShared

final class WidgetSnapshotPublisher {
    func publish(status: BatteryStatus, settings: AlarmSettingsSnapshot) {
        let snapshot = BatteryPanicWidgetSnapshot(
            percentage: status.percentage,
            hasBattery: status.hasBattery,
            isCharging: status.isCharging,
            isPluggedIn: status.isPluggedIn,
            thresholdPercentage: settings.thresholdPercentage,
            isPaused: settings.isPaused,
            updatedAt: Date()
        )

        BatteryPanicWidgetStorage.writeSnapshot(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
