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
        for minute in 0...30 {
            let isInitialCharge = minute < 5
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(TimeInterval((minute - 30) * 60)),
                    percentage: isInitialCharge
                        ? 22 + (minute / 3)
                        : 23 - Int((Double(minute - 5) * 5 / 25).rounded(.down)),
                    powerSource: isInitialCharge ? .acPower : .batteryPower,
                    isCharging: isInitialCharge
                )
            )
        }

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
#endif
