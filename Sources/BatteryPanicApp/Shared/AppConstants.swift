import Foundation

enum AppConstants {
    static let appName = "Battery Panic"
    static let defaultThreshold = 10
    static let defaultChargeReminderThreshold = 80
    static let criticalBatteryThreshold = 2
    static let chargeReminderResetMargin = 5
    static let pollInterval: TimeInterval = 5
    static let previewAlarmDuration: TimeInterval = 4
    static let alarmSnoozeDuration: TimeInterval = 30 * 60
}
