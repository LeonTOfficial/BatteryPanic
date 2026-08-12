import AppKit
import XCTest
@testable import BatteryPanicApp

final class MenuBarSnoozeIndicatorPolicyTests: XCTestCase {
    func testOnlyPausedLowBatteryOnBatteryPowerIsHighlighted() {
        let pausedSettings = settings(isPaused: true)
        let lowOnBattery = status(percentage: 10, powerSource: .batteryPower, hasBattery: true)

        XCTAssertTrue(
            MenuBarSnoozeIndicatorPolicy.shouldHighlight(
                status: lowOnBattery,
                settings: pausedSettings
            )
        )
        XCTAssertFalse(
            MenuBarSnoozeIndicatorPolicy.shouldHighlight(
                status: status(percentage: 11, powerSource: .batteryPower, hasBattery: true),
                settings: pausedSettings
            )
        )
        XCTAssertFalse(
            MenuBarSnoozeIndicatorPolicy.shouldHighlight(
                status: status(percentage: 10, powerSource: .acPower, hasBattery: true),
                settings: pausedSettings
            )
        )
        XCTAssertFalse(
            MenuBarSnoozeIndicatorPolicy.shouldHighlight(
                status: lowOnBattery,
                settings: settings(isPaused: false)
            )
        )
        XCTAssertFalse(
            MenuBarSnoozeIndicatorPolicy.shouldHighlight(
                status: status(percentage: 10, powerSource: .unknown, hasBattery: false),
                settings: pausedSettings
            )
        )
    }

    @MainActor
    func testControllerPulsesOnlyThePercentageStopsOnRecoveryAndRegistersNoShortcuts() throws {
        let suiteName = "BatteryPanicMenuBarTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.set(true, forKey: "migratedLegacyBundleSettings")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settingsStore = AppSettingsStore(defaults: defaults)
        settingsStore.setThresholdPercentage(20)
        settingsStore.snoozeAlarm(for: 1_800)
        var reduceMotion = false
        let controller = MenuBarController(
            settingsStore: settingsStore,
            historyStore: BatteryHistoryStore(storageURL: nil),
            reduceMotionEnabled: { reduceMotion }
        )
        controller.start()
        defer { controller.stop() }

        let lowStatus = status(
            percentage: 18,
            powerSource: .batteryPower,
            hasBattery: true
        )
        controller.update(status: lowStatus)

        XCTAssertTrue(controller.isPercentagePulseActiveForTesting)
        XCTAssertEqual(controller.statusTitleForTesting?.string, "18%")
        XCTAssertTrue(controller.menuKeyEquivalentsForTesting.allSatisfy(\.isEmpty))
        XCTAssertNotNil(
            controller.statusTitleForTesting?.attribute(
                .foregroundColor,
                at: 0,
                effectiveRange: nil
            ) as? NSColor
        )

        controller.update(
            status: status(
                percentage: 18,
                powerSource: .acPower,
                hasBattery: true
            )
        )
        XCTAssertFalse(controller.isPercentagePulseActiveForTesting)
        XCTAssertNil(
            controller.statusTitleForTesting?.attribute(
                .foregroundColor,
                at: 0,
                effectiveRange: nil
            )
        )

        reduceMotion = true
        controller.update(status: lowStatus)
        XCTAssertFalse(controller.isPercentagePulseActiveForTesting)
        XCTAssertNotNil(
            controller.statusTitleForTesting?.attribute(
                .foregroundColor,
                at: 0,
                effectiveRange: nil
            ) as? NSColor
        )
    }

    private func status(
        percentage: Int,
        powerSource: PowerSource,
        hasBattery: Bool
    ) -> BatteryStatus {
        BatteryStatus(
            percentage: percentage,
            powerSource: powerSource,
            isCharging: false,
            hasBattery: hasBattery
        )
    }

    private func settings(isPaused: Bool) -> AlarmSettingsSnapshot {
        AlarmSettingsSnapshot(
            thresholdPercentage: 10,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: isPaused,
            pauseUntil: isPaused ? Date().addingTimeInterval(1_800) : nil,
            hasCompletedOnboarding: true
        )
    }
}
