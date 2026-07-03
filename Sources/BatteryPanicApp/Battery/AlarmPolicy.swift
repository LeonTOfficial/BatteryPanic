import Foundation

enum AlarmPolicy {
    static func shouldShowAlarm(status: BatteryStatus, settings: AlarmSettingsSnapshot) -> Bool {
        guard !settings.isPaused else { return false }
        guard status.hasBattery else { return false }
        guard !status.isPluggedIn else { return false }
        return status.percentage <= settings.thresholdPercentage
    }

    static func isCriticalLowBattery(status: BatteryStatus) -> Bool {
        guard status.hasBattery else { return false }
        guard !status.isPluggedIn else { return false }
        return status.percentage <= AppConstants.criticalBatteryThreshold
    }

    static func shouldShowChargeReminder(
        status: BatteryStatus,
        settings: AlarmSettingsSnapshot,
        alreadyShownThisSession: Bool
    ) -> Bool {
        guard !settings.isPaused else { return false }
        guard settings.chargeReminderEnabled else { return false }
        guard !alreadyShownThisSession else { return false }
        guard status.hasBattery else { return false }
        guard status.isPluggedIn else { return false }
        return status.percentage >= settings.chargeReminderThresholdPercentage
    }

    static func shouldResetChargeReminder(status: BatteryStatus, settings: AlarmSettingsSnapshot) -> Bool {
        guard status.hasBattery else { return true }
        guard status.isPluggedIn else { return true }
        return status.percentage <= settings.chargeReminderThresholdPercentage - AppConstants.chargeReminderResetMargin
    }
}
