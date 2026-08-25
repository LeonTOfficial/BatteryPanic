import AppKit
import Darwin

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: AppCoordinator?
#if DEBUG
    private var dashboardQADefaultsSuiteName: String?
#endif

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard ensureSingleRunningInstance() else { return }

        let coordinator = makeCoordinator()
        self.coordinator = coordinator
        coordinator.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
#if DEBUG
        if let dashboardQADefaultsSuiteName {
            UserDefaults.standard.removePersistentDomain(forName: dashboardQADefaultsSuiteName)
        }
#endif
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        coordinator?.showSettingsForReopen()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func ensureSingleRunningInstance() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return true
        }

        let currentProcessID = getpid()
        let existingApp = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .first { $0.processIdentifier != currentProcessID }

        guard let existingApp else {
            return true
        }

        existingApp.activate(options: [.activateIgnoringOtherApps])
        NSApp.terminate(nil)
        return false
    }

    private func makeCoordinator() -> AppCoordinator {
#if DEBUG
        if ProcessInfo.processInfo.environment["BATTERY_PANIC_DASHBOARD_QA"] == "1" {
            return makeDashboardQACoordinator()
        }
#endif
        return AppCoordinator()
    }

#if DEBUG
    /// Deterministic, opt-in fixture for native menu screenshot QA. This code
    /// is not compiled into release builds and never writes production history.
    private func makeDashboardQACoordinator() -> AppCoordinator {
        let now = Date()
        let suiteName = "com.leontofficial.batterypanic.dashboard-qa.\(getpid())"
        dashboardQADefaultsSuiteName = suiteName
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(true, forKey: "migratedLegacyBundleSettings")

        let settingsStore = AppSettingsStore(defaults: defaults)
        settingsStore.setThresholdPercentage(20)
        settingsStore.setSoundEnabled(false)
        settingsStore.setHasCompletedOnboarding(true)
        settingsStore.snoozeAlarm(for: 24 * 60)

        let status = BatteryStatus(
            percentage: 18,
            powerSource: .batteryPower,
            isCharging: false,
            hasBattery: true,
            health: .good,
            timeRemainingMinutes: 42,
            timestamp: now
        )
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        DashboardQAHistoryFixture.populate(historyStore, endingAt: now)

        return AppCoordinator(
            settingsStore: settingsStore,
            batteryMonitor: BatteryMonitor(
                provider: DashboardQABatteryProvider(status: status),
                interval: 3_600
            ),
            batteryHistoryStore: historyStore,
            dashboardDefaults: defaults,
            checksForUpdatesInBackground: false
        )
    }
#endif
}

#if DEBUG
private final class DashboardQABatteryProvider: BatteryProviding {
    private let status: BatteryStatus

    init(status: BatteryStatus) {
        self.status = status
    }

    func currentStatus() -> BatteryStatus {
        status
    }
}

/// Deterministic history used only by opt-in DEBUG visual QA and screenshot tests.
/// Release builds compile none of this fixture.
enum DashboardQAHistoryFixture {
    static func populate(_ historyStore: BatteryHistoryStore, endingAt now: Date) {
        for hour in (-7 * 24)...(-3) {
            let cycleHour = ((hour % 24) + 24) % 24
            let isCharging = (2...5).contains(cycleHour)
            let isConnectedNotCharging = cycleHour == 6
            let percentage: Int
            if isCharging {
                percentage = 40 + ((cycleHour - 2) * 15)
            } else if cycleHour > 5 {
                percentage = max(22, 85 - ((cycleHour - 5) * 4))
            } else {
                percentage = 32 - (cycleHour * 3)
            }
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(TimeInterval(hour * 60 * 60)),
                    percentage: percentage,
                    powerSource: (isCharging || isConnectedNotCharging) ? .acPower : .batteryPower,
                    isCharging: isCharging
                )
            )
        }

        for minutesAgo in stride(from: 120, through: 35, by: -5) {
            let beginsEarlierCycle = minutesAgo > 60
            let cycleStart = beginsEarlierCycle ? 120 : 60
            let elapsed = cycleStart - minutesAgo
            let isCharging = elapsed <= 10
            let base = beginsEarlierCycle ? 35 : 21
            let peak = base + 4
            let percentage: Int
            if isCharging {
                percentage = base + ((elapsed / 5) * 2)
            } else {
                let dischargeStep = beginsEarlierCycle ? 2 : 1
                percentage = peak - (((elapsed - 10) / 5) * dischargeStep)
            }
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(TimeInterval(-minutesAgo * 60)),
                    percentage: percentage,
                    powerSource: isCharging ? .acPower : .batteryPower,
                    isCharging: isCharging
                )
            )
        }

        for minute in 0...30 {
            let isCharging = (4...8).contains(minute)
            let percentage: Int
            if minute < 4 {
                percentage = 22 - (minute / 2)
            } else if isCharging {
                percentage = 21 + (minute - 4)
            } else {
                percentage = 25 - Int((Double(minute - 8) * 7 / 22).rounded(.down))
            }
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(TimeInterval((minute - 30) * 60)),
                    percentage: percentage,
                    powerSource: isCharging ? .acPower : .batteryPower,
                    isCharging: isCharging
                )
            )
        }
    }
}
#endif
