import AppKit
import Foundation

final class AppCoordinator {
    private let settingsStore: AppSettingsStore
    private let batteryMonitor: BatteryMonitor
    private let overlayManager: OverlayManager
    private let soundPlayer: WarningSoundPlaying
    private let loginItemService: LoginItemService
    private let menuBarController: MenuBarController
    private let settingsWindowController: SettingsWindowController
    private let onboardingWindowController: OnboardingWindowController
    private let appUpdater = AppUpdater()

    private var latestStatus: BatteryStatus?
    private var alarmVisible = false
    private var chargeReminderVisible = false
    private var chargeReminderShownThisSession = false
    private var chargeReminderArmedThisSession = false
    private var chargeReminderToken = UUID()
    private var testAlarmVisible = false
    private var testAlarmToken = UUID()
    private var testAlarmTimer: Timer?
    private var soundPreviewToken = UUID()
    private var soundPreviewActive = false
    private var activeAlarmSoundName: String?

    init(
        settingsStore: AppSettingsStore = AppSettingsStore(),
        batteryMonitor: BatteryMonitor = BatteryMonitor(),
        overlayManager: OverlayManager = OverlayManager(),
        soundPlayer: WarningSoundPlaying = WarningSoundPlayer(),
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
        testAlarmTimer?.invalidate()
        testAlarmTimer = nil
        soundPreviewToken = UUID()
        soundPreviewActive = false
        activeAlarmSoundName = nil
        soundPlayer.stop()
        overlayManager.hide()
    }

    func showSettingsForReopen() {
        menuBarController.ensureStatusItemVisible()
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
            self?.previewWarningSound(named: soundName)
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
        if AlarmPolicy.shouldResetChargeReminder(status: status, settings: settings) {
            chargeReminderShownThisSession = false
            chargeReminderArmedThisSession = false
            hideChargeReminder()
        }
        if AlarmPolicy.shouldArmChargeReminder(status: status, settings: settings) {
            chargeReminderArmedThisSession = true
        }

        if settings.isPaused {
            hideActiveAlarm()
            hideChargeReminder()
            return
        }

        if AlarmPolicy.shouldShowAlarm(status: status, settings: settings) {
            hideChargeReminder()
            let isCritical = AlarmPolicy.isCriticalLowBattery(status: status)
            overlayManager.show(
                status: status,
                pulseEnabled: settings.pulseEnabled,
                pulseSpeed: settings.pulseSpeed,
                pulseIntensity: isCritical ? max(settings.pulseIntensity, 1.35) : settings.pulseIntensity,
                displayMode: isCritical ? .criticalBattery : .lowBattery,
                isTest: false
            )
            alarmVisible = true
            synchronizeActiveAlarmSound(using: settings)
            menuBarController.setAlarmVisible(true, mode: isCritical ? .critical : .active)
            return
        }

        if alarmVisible {
            hideActiveAlarm()
        }

        if AlarmPolicy.shouldShowChargeReminder(
            status: status,
            settings: settings,
            alreadyShownThisSession: chargeReminderShownThisSession,
            hasObservedBelowThresholdThisSession: chargeReminderArmedThisSession
        ) {
            showChargeReminder(status: status, settings: settings)
        }
    }

    private func hideActiveAlarm() {
        if alarmVisible {
            overlayManager.hide()
        }
        soundPlayer.stop()
        activeAlarmSoundName = nil
        alarmVisible = false
        menuBarController.setAlarmVisible(false)
    }

    private func showChargeReminder(status: BatteryStatus, settings: AlarmSettingsSnapshot) {
        let token = UUID()
        chargeReminderToken = token
        chargeReminderVisible = true
        chargeReminderShownThisSession = true

        overlayManager.show(
            status: status,
            pulseEnabled: true,
            pulseSpeed: 0.85,
            pulseIntensity: 0.95,
            displayMode: .chargeReminder,
            isTest: false
        )
        menuBarController.setAlarmVisible(true, mode: .chargeReminder)
        cancelSoundPreview()
        playWarningSound(using: settings, looping: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.previewAlarmDuration) { [weak self] in
            guard let self, self.chargeReminderVisible, self.chargeReminderToken == token else { return }
            self.hideChargeReminder()
        }
    }

    private func hideChargeReminder() {
        guard chargeReminderVisible else { return }
        chargeReminderVisible = false
        overlayManager.hide()
        soundPlayer.stop()
        activeAlarmSoundName = nil
        menuBarController.setAlarmVisible(false)
    }

    private func showSettings() {
        menuBarController.ensureStatusItemVisible()
        settingsWindowController.show()
    }

    private func showWelcome() {
        menuBarController.ensureStatusItemVisible()
        onboardingWindowController.show()
    }

    private func openGitHub() {
        guard let url = URL(string: "https://github.com/LeonTOfficial") else { return }
        NSWorkspace.shared.open(url)
    }

    private func showLaunchWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self else { return }
            guard !settingsStore.snapshot().hasCompletedOnboarding else {
                menuBarController.ensureStatusItemVisible()
                return
            }

            onboardingWindowController.show()
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
        hideChargeReminder()
    }

    private func showTestAlarm() {
        let settings = settingsStore.snapshot()
        let status = BatteryStatus.lowBatteryPreview(threshold: settings.thresholdPercentage)
        let token = UUID()

        testAlarmTimer?.invalidate()
        cancelSoundPreview()
        hideActiveAlarm()
        hideChargeReminder()
        soundPlayer.stop()
        testAlarmToken = token
        testAlarmVisible = true
        menuBarController.setAlarmVisible(true, mode: .preview)
        overlayManager.show(
            status: status,
            pulseEnabled: settings.pulseEnabled,
            pulseSpeed: settings.pulseSpeed,
            pulseIntensity: settings.pulseIntensity,
            displayMode: .lowBattery,
            isTest: true
        )
        if settings.soundEnabled {
            playPreviewSound(named: settings.selectedSoundName)
        }

        let timer = Timer(timeInterval: AppConstants.previewAlarmDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.finishTestAlarm(token: token, reevaluateCurrentStatus: true)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        testAlarmTimer = timer
    }

    private func finishTestAlarm(token: UUID, reevaluateCurrentStatus: Bool) {
        guard testAlarmVisible, testAlarmToken == token else { return }
        testAlarmTimer?.invalidate()
        testAlarmTimer = nil
        testAlarmVisible = false
        soundPlayer.stop()
        overlayManager.hide()
        menuBarController.setAlarmVisible(false)

        if reevaluateCurrentStatus, let latestStatus {
            evaluateAlarm(for: latestStatus)
        }
    }

    private func previewWarningSound(named soundName: String) {
        let token = UUID()
        soundPreviewToken = token
        soundPreviewActive = true
        playPreviewSound(named: soundName)

        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.previewAlarmDuration) { [weak self] in
            guard let self, self.soundPreviewToken == token else { return }
            self.soundPreviewActive = false
            self.restoreSoundAfterPreview()
        }
    }

    private func playPreviewSound(named soundName: String) {
        let warningSound = WarningSound.sound(named: soundName)
        if warningSound.source == .siren {
            soundPlayer.playWarning(named: soundName)
        } else {
            soundPlayer.playLoopingWarning(named: soundName)
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

    private func synchronizeActiveAlarmSound(using settings: AlarmSettingsSnapshot) {
        guard !soundPreviewActive else { return }
        guard settings.soundEnabled else {
            soundPlayer.stop()
            activeAlarmSoundName = nil
            return
        }
        guard activeAlarmSoundName != settings.selectedSoundName else { return }

        soundPlayer.playLoopingWarning(named: settings.selectedSoundName)
        activeAlarmSoundName = settings.selectedSoundName
    }

    private func cancelSoundPreview() {
        guard soundPreviewActive else { return }
        soundPreviewToken = UUID()
        soundPreviewActive = false
    }

    private func restoreSoundAfterPreview() {
        activeAlarmSoundName = nil
        guard alarmVisible else {
            soundPlayer.stop()
            return
        }
        synchronizeActiveAlarmSound(using: settingsStore.snapshot())
    }
}
