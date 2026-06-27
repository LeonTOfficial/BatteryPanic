import AppKit

enum AlarmDisplayMode {
    case active
    case preview
}

final class MenuBarController: NSObject {
    private let settingsStore: AppSettingsStore
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let headerView = BatteryMenuHeaderView()
    private let detailsView = BatteryMenuDetailsView()
    private let headerItem = NSMenuItem()
    private let detailsItem = NSMenuItem()

    private let pauseItem = NSMenuItem(title: "Pause Alarm", action: #selector(togglePause), keyEquivalent: "")
    private var latestStatus: BatteryStatus?
    private var alarmSummary = "Idle"
    private var oneTimePauseActive = false

    var onOpenSettings: (() -> Void)?
    var onOpenWelcome: (() -> Void)?
    var onTestAlarm: (() -> Void)?
    var onTogglePause: (() -> Void)?
    var onOpenGitHub: (() -> Void)?
    var onQuit: (() -> Void)?
    var onConfigureUpdaterMenuItem: ((NSMenuItem) -> Void)?

    init(settingsStore: AppSettingsStore) {
        self.settingsStore = settingsStore
        super.init()
    }

    func start() {
        configureMenu()
        statusItem.menu = menu
        updateSettings()
    }

    func update(status: BatteryStatus) {
        latestStatus = status
        updateButton(for: status)
        headerView.update(status: status, settings: settingsStore.snapshot())
        updateDetails()
    }

    func updateSettings() {
        let snapshot = settingsStore.snapshot()
        pauseItem.title = snapshot.isPaused || oneTimePauseActive ? "Resume Alarm" : "Pause Alarm"
        headerView.update(status: latestStatus, settings: snapshot)
        updateDetails()
        if let latestStatus {
            updateButton(for: latestStatus)
        }
    }

    func setAlarmVisible(_ visible: Bool, mode: AlarmDisplayMode = .active) {
        if visible {
            alarmSummary = mode == .preview ? "Preview running" : "Visible"
        } else {
            alarmSummary = "Idle"
        }
        updateDetails()
    }

    func setOneTimePauseActive(_ active: Bool) {
        oneTimePauseActive = active
        alarmSummary = active ? "Paused for this alarm" : alarmSummary
        updateSettings()
    }

    private func updateButton(for status: BatteryStatus) {
        if let button = statusItem.button {
            let snapshot = settingsStore.snapshot()
            let appearance = BatteryStatusAppearance.appearance(
                for: status,
                threshold: snapshot.thresholdPercentage
            )
            button.image = MenuBarIconFactory.image(appearance: appearance, percentage: status.percentage)
            button.imagePosition = .imageLeading
            button.title = BatteryFormatter.menuTitle(
                for: status,
                threshold: snapshot.thresholdPercentage
            )
        }
    }

    private func configureMenu() {
        if let button = statusItem.button {
            button.title = "BP --"
            button.toolTip = "Battery Panic"
            button.image = MenuBarIconFactory.image(isLow: false, isPaused: false)
            button.imagePosition = .imageLeading
        }

        headerItem.view = headerView
        detailsItem.view = detailsView
        pauseItem.target = self

        let testItem = NSMenuItem(title: "Preview Red Screen", action: #selector(testAlarm), keyEquivalent: "t")
        testItem.target = self

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self

        let welcomeItem = NSMenuItem(title: "Welcome & Setup...", action: #selector(openWelcome), keyEquivalent: "")
        welcomeItem.target = self

        let updateItem = NSMenuItem(title: "Check for Updates...", action: nil, keyEquivalent: "")
        onConfigureUpdaterMenuItem?(updateItem)

        let creatorItem = NSMenuItem(title: "Created by Leon.T", action: nil, keyEquivalent: "")
        creatorItem.isEnabled = false

        let gitHubItem = NSMenuItem(title: "GitHub: LeonTOfficial", action: #selector(openGitHub), keyEquivalent: "")
        gitHubItem.target = self

        let quitItem = NSMenuItem(title: "Quit Battery Panic", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self

        menu.addItem(headerItem)
        menu.addItem(.separator())
        menu.addItem(detailsItem)
        menu.addItem(.separator())
        menu.addItem(testItem)
        menu.addItem(pauseItem)
        menu.addItem(settingsItem)
        menu.addItem(welcomeItem)
        menu.addItem(updateItem)
        menu.addItem(.separator())
        menu.addItem(creatorItem)
        menu.addItem(gitHubItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
    }

    private func updateDetails() {
        detailsView.update(
            status: latestStatus,
            settings: settingsStore.snapshot(),
            alarmSummary: alarmSummary
        )
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func openWelcome() {
        onOpenWelcome?()
    }

    @objc private func testAlarm() {
        onTestAlarm?()
    }

    @objc private func togglePause() {
        onTogglePause?()
    }

    @objc private func openGitHub() {
        onOpenGitHub?()
    }

    @objc private func quit() {
        onQuit?()
    }
}
