import Foundation

@main
struct AlarmPolicyTestRunner {
    static func main() {
        var suite = TestSuite()

        do {
            let status = BatteryStatus(
                percentage: 9,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true
            )
            suite.expect(
                "shows alarm below threshold and unplugged",
                AlarmPolicy.shouldShowAlarm(status: status, settings: settings(threshold: 10))
            )
        }

        do {
            let status = BatteryStatus(
                percentage: 10,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true
            )
            suite.expect(
                "shows alarm at exact threshold",
                AlarmPolicy.shouldShowAlarm(status: status, settings: settings(threshold: 10))
            )
        }

        do {
            let status = BatteryStatus(
                percentage: 11,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true
            )
            suite.expect(
                "does not show alarm above threshold",
                !AlarmPolicy.shouldShowAlarm(status: status, settings: settings(threshold: 10))
            )
        }

        do {
            let status = BatteryStatus(
                percentage: 4,
                powerSource: .acPower,
                isCharging: true,
                hasBattery: true
            )
            suite.expect(
                "does not show alarm while plugged in",
                !AlarmPolicy.shouldShowAlarm(status: status, settings: settings(threshold: 10))
            )
        }

        do {
            let status = BatteryStatus(
                percentage: 4,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true
            )
            suite.expect(
                "does not show alarm while paused",
                !AlarmPolicy.shouldShowAlarm(status: status, settings: settings(threshold: 10, isPaused: true))
            )
        }

        suite.expect(
            "does not show alarm without a battery",
            !AlarmPolicy.shouldShowAlarm(status: .noBattery(), settings: settings(threshold: 10))
        )

        do {
            let status = BatteryStatus(
                percentage: 80,
                powerSource: .acPower,
                isCharging: true,
                hasBattery: true
            )
            suite.expect(
                "shows charging reminder at exact threshold while plugged in",
                AlarmPolicy.shouldShowChargeReminder(
                    status: status,
                    settings: settings(threshold: 10, chargeThreshold: 80),
                    alreadyShownThisSession: false
                )
            )
        }

        do {
            let status = BatteryStatus(
                percentage: 79,
                powerSource: .acPower,
                isCharging: true,
                hasBattery: true
            )
            suite.expect(
                "does not show charging reminder below threshold",
                !AlarmPolicy.shouldShowChargeReminder(
                    status: status,
                    settings: settings(threshold: 10, chargeThreshold: 80),
                    alreadyShownThisSession: false
                )
            )
        }

        do {
            let status = BatteryStatus(
                percentage: 85,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true
            )
            suite.expect(
                "does not show charging reminder while unplugged",
                !AlarmPolicy.shouldShowChargeReminder(
                    status: status,
                    settings: settings(threshold: 10, chargeThreshold: 80),
                    alreadyShownThisSession: false
                )
            )
        }

        do {
            let status = BatteryStatus(
                percentage: 86,
                powerSource: .acPower,
                isCharging: true,
                hasBattery: true
            )
            suite.expect(
                "does not repeat charging reminder in the same charging session",
                !AlarmPolicy.shouldShowChargeReminder(
                    status: status,
                    settings: settings(threshold: 10, chargeThreshold: 80),
                    alreadyShownThisSession: true
                )
            )
        }

        do {
            let status = BatteryStatus(
                percentage: 85,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true
            )
            suite.expect(
                "resets charging reminder after unplugging",
                AlarmPolicy.shouldResetChargeReminder(status: status, settings: settings(threshold: 10, chargeThreshold: 80))
            )
        }

        do {
            let status = BatteryStatus(
                percentage: 75,
                powerSource: .acPower,
                isCharging: true,
                hasBattery: true
            )
            suite.expect(
                "resets charging reminder after dropping clearly below threshold",
                AlarmPolicy.shouldResetChargeReminder(status: status, settings: settings(threshold: 10, chargeThreshold: 80))
            )
        }

        do {
            let status = BatteryStatus(
                percentage: 2,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true
            )
            suite.expect("critical mode activates at 2%", AlarmPolicy.isCriticalLowBattery(status: status))
        }

        do {
            let status = BatteryStatus(
                percentage: 3,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true
            )
            suite.expect(
                "normal low-battery mode still works above critical threshold",
                AlarmPolicy.shouldShowAlarm(status: status, settings: settings(threshold: 10))
                    && !AlarmPolicy.isCriticalLowBattery(status: status)
            )
        }

        do {
            let status = BatteryStatus.lowBatteryPreview(threshold: 10)
            suite.expect("preview uses a low unplugged battery", status.percentage == 9 && !status.isPluggedIn)
        }

        suite.finish()
    }

    private static func settings(
        threshold: Int,
        chargeReminderEnabled: Bool = true,
        chargeThreshold: Int = 80,
        isPaused: Bool = false
    ) -> AlarmSettingsSnapshot {
        AlarmSettingsSnapshot(
            thresholdPercentage: threshold,
            chargeReminderEnabled: chargeReminderEnabled,
            chargeReminderThresholdPercentage: chargeThreshold,
            pulseEnabled: true,
            pulseSpeed: 1.0,
            pulseIntensity: 1.0,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            launchAtLoginEnabled: false,
            isPaused: isPaused,
            hasCompletedOnboarding: true
        )
    }
}

private struct TestSuite {
    private var passed = 0
    private var failed = 0

    mutating func expect(_ name: String, _ condition: Bool) {
        if condition {
            passed += 1
            print("PASS: \(name)")
        } else {
            failed += 1
            print("FAIL: \(name)")
        }
    }

    func finish() -> Never {
        print("AlarmPolicy tests: \(passed) passed, \(failed) failed")
        exit(failed == 0 ? 0 : 1)
    }
}
