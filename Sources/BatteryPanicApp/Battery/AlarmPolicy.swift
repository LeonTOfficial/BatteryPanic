import Foundation

enum AlarmPolicy {
    static func shouldShowAlarm(status: BatteryStatus, settings: AlarmSettingsSnapshot) -> Bool {
        guard !settings.isPaused else { return false }
        guard status.hasBattery else { return false }
        guard !status.isPluggedIn else { return false }
        return status.percentage <= settings.thresholdPercentage
    }
}
