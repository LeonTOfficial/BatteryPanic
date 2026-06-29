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
    private let widgetSnapshotPublisher = WidgetSnapshotPublisher()
    private let appUpdater = AppUpdater()

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
        showLaunchWindow()
        batteryMonitor.onStatusUpdate = { [weak self] status in
            self?.handleBatteryStatus(status)
        }
        batteryMonitor.start()
        appUpdater.checkForUpdatesInBackgroundAfterLaunch()
    }

    func stop() {
        batteryMonitor.stop()
        soundPlayer.stop()
        overlayManager.hide()
    }

    func showSettingsForReopen() {
        showSettings()
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
        menuBarController.onConfigureUpdaterMenuItem = { [weak self] item in
            self?.appUpdater.wireCheckForUpdatesMenuItem(item)
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
        settingsWindowController.onCheckForUpdates = { [weak self] in
            self?.appUpdater.checkForUpdates()
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
            widgetSnapshotPublisher.publish(status: status, settings: settingsStore.snapshot())
            evaluateAlarm(for: status)
        }
    }

    private func handleSettingsChanged() {
        menuBarController.updateSettings()
        guard let latestStatus else { return }
        widgetSnapshotPublisher.publish(status: latestStatus, settings: settingsStore.snapshot())
        evaluateAlarm(for: latestStatus)
    }

    private func evaluateAlarm(for status: BatteryStatus) {
        guard !testAlarmVisible else { return }

        let settings = settingsStore.snapshot()
        let shouldShow = AlarmPolicy.shouldShowAlarm(status: status, settings: settings)

        if settings.isPaused {
            hideActiveAlarm()
            return
        }

        if !shouldShow {
            hideActiveAlarm()
            return
        }

        if shouldShow {
            overlayManager.show(
                status: status,
                pulseEnabled: settings.pulseEnabled,
                pulseSpeed: settings.pulseSpeed,
                pulseIntensity: settings.pulseIntensity,
                isTest: false
            )
            if !alarmVisible {
                playWarningSound(using: settings, looping: true)
            }
            alarmVisible = true
            menuBarController.setAlarmVisible(true)
        }
    }

    private func hideActiveAlarm() {
        overlayManager.hide()
        soundPlayer.stop()
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

    private func showLaunchWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self else { return }
            if settingsStore.snapshot().hasCompletedOnboarding {
                settingsWindowController.show()
            } else {
                onboardingWindowController.show()
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func togglePause() {
        if settingsStore.snapshot().isPaused {
            settingsStore.clearSnooze()
            if let latestStatus {
                evaluateAlarm(for: latestStatus)
            }
            return
        }

        settingsStore.snoozeAlarm()
        hideActiveAlarm()
    }

    private func showTestAlarm() {
        let settings = settingsStore.snapshot()
        let status = BatteryStatus.lowBatteryPreview(threshold: settings.thresholdPercentage)
        let token = UUID()

        soundPlayer.stop()
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

        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.previewAlarmDuration) { [weak self] in
            guard let self, self.testAlarmVisible, self.testAlarmToken == token else { return }
            self.testAlarmVisible = false
            self.soundPlayer.stop()
            if let latestStatus = self.latestStatus {
                self.evaluateAlarm(for: latestStatus)
            } else {
                self.overlayManager.hide()
                self.menuBarController.setAlarmVisible(false)
            }
        }
    }

    private func playWarningSound(using settings: AlarmSettingsSnapshot, looping: Bool = false) {
        guard settings.soundEnabled else { return }
        if looping {
            soundPlayer.playLoopingWarning(named: settings.selectedSoundName)
        } else {
            soundPlayer.playWarning(named: settings.selectedSoundName)
        }
    }
}
