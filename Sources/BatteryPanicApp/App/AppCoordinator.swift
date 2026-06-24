import AppKit
import Foundation

final class AppCoordinator {
    private let settingsStore: AppSettingsStore
    private let batteryMonitor: BatteryMonitor
    private let overlayManager: OverlayManager
    private let soundPlayer: WarningSoundPlayer
    private let loginItemService: LoginItemService
    private let menuBarController: MenuBarController
    private let settingsWindowController: SettingsWindowController
    private let onboardingWindowController: OnboardingWindowController

    private var latestStatus: BatteryStatus?
    private var alarmVisible = false
    private var testAlarmVisible = false
    private var testAlarmToken = UUID()

    init(
        settingsStore: AppSettingsStore = AppSettingsStore(),
        batteryMonitor: BatteryMonitor = BatteryMonitor(),
        overlayManager: OverlayManager = OverlayManager(),
        soundPlayer: WarningSoundPlayer = WarningSoundPlayer(),
        loginItemService: LoginItemService = LoginItemService()
    ) {
        self.settingsStore = settingsStore
        self.batteryMonitor = batteryMonitor
        self.overlayManager = overlayManager
        self.soundPlayer = soundPlayer
        self.loginItemService = loginItemService
        self.menuBarController = MenuBarController(settingsStore: settingsStore)
        self.settingsWindowController = SettingsWindowController(
            settingsStore: settingsStore,
            loginItemService: loginItemService
        )
        self.onboardingWindowController = OnboardingWindowController(
            settingsStore: settingsStore,
            loginItemService: loginItemService
        )

        wireCallbacks()
    }

    func start() {
        menuBarController.start()
        batteryMonitor.onStatusUpdate = { [weak self] status in
            self?.handleBatteryStatus(status)
        }
        batteryMonitor.start()
        showOnboardingIfNeeded()
    }

    func stop() {
        batteryMonitor.stop()
        overlayManager.hide()
    }

    private func wireCallbacks() {
        menuBarController.onOpenSettings = { [weak self] in
            self?.showSettings()
        }
        menuBarController.onOpenWelcome = { [weak self] in
            self?.showWelcome()
        }
        menuBarController.onTestAlarm = { [weak self] in
            self?.showTestAlarm()
        }
        menuBarController.onTogglePause = { [weak self] in
            self?.togglePause()
        }
        menuBarController.onOpenGitHub = { [weak self] in
            self?.openGitHub()
        }
        menuBarController.onQuit = {
            NSApp.terminate(nil)
        }

        settingsWindowController.onTestAlarm = { [weak self] in
            self?.showTestAlarm()
        }
        settingsWindowController.onTestSound = { [weak self] soundName in
            self?.soundPlayer.playWarning(named: soundName)
        }
        settingsWindowController.onOpenGitHub = { [weak self] in
            self?.openGitHub()
        }
        onboardingWindowController.onTestAlarm = { [weak self] in
            self?.showTestAlarm()
        }
        onboardingWindowController.onOpenSettings = { [weak self] in
            self?.showSettings()
        }
        onboardingWindowController.onOpenGitHub = { [weak self] in
            self?.openGitHub()
        }

        settingsStore.onChange = { [weak self] _ in
            self?.handleSettingsChanged()
        }
    }

    private func handleBatteryStatus(_ status: BatteryStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            latestStatus = status
            menuBarController.update(status: status)
            evaluateAlarm(for: status)
        }
    }

    private func handleSettingsChanged() {
        menuBarController.updateSettings()
        guard let latestStatus else { return }
        evaluateAlarm(for: latestStatus)
    }

    private func evaluateAlarm(for status: BatteryStatus) {
        guard !testAlarmVisible else { return }

        let settings = settingsStore.snapshot()
        let shouldShow = AlarmPolicy.shouldShowAlarm(status: status, settings: settings)

        if shouldShow {
            overlayManager.show(
                status: status,
                pulseEnabled: settings.pulseEnabled,
                pulseSpeed: settings.pulseSpeed,
                pulseIntensity: settings.pulseIntensity,
                isTest: false
            )
            if !alarmVisible && settings.soundEnabled {
                soundPlayer.playWarning(named: settings.selectedSoundName)
            }
            alarmVisible = true
            menuBarController.setAlarmVisible(true)
        } else {
            hideActiveAlarm()
        }
    }

    private func hideActiveAlarm() {
        overlayManager.hide()
        alarmVisible = false
        menuBarController.setAlarmVisible(false)
    }

    private func showSettings() {
        settingsWindowController.show()
    }

    private func showWelcome() {
        onboardingWindowController.show()
    }

    private func openGitHub() {
        guard let url = URL(string: "https://github.com/LeonTOfficial") else { return }
        NSWorkspace.shared.open(url)
    }

    private func showOnboardingIfNeeded() {
        guard !settingsStore.snapshot().hasCompletedOnboarding else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.onboardingWindowController.show()
        }
    }

    private func togglePause() {
        let current = settingsStore.snapshot().isPaused
        settingsStore.setPaused(!current)
    }

    private func showTestAlarm() {
        let settings = settingsStore.snapshot()
        let status = BatteryStatus.lowBatteryPreview(threshold: settings.thresholdPercentage)
        let token = UUID()

        testAlarmToken = token
        testAlarmVisible = true
        menuBarController.setAlarmVisible(true, mode: .preview)
        overlayManager.show(
            status: status,
            pulseEnabled: settings.pulseEnabled,
            pulseSpeed: settings.pulseSpeed,
            pulseIntensity: settings.pulseIntensity,
            isTest: true
        )
        if settings.soundEnabled {
            soundPlayer.playWarning(named: settings.selectedSoundName)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + settings.previewDuration) { [weak self] in
            guard let self, testAlarmVisible, testAlarmToken == token else { return }
            testAlarmVisible = false
            if let latestStatus {
                evaluateAlarm(for: latestStatus)
            } else {
                overlayManager.hide()
                menuBarController.setAlarmVisible(false)
            }
        }
    }
}
