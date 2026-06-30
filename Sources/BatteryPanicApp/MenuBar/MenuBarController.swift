import AppKit

enum AlarmDisplayMode {
    case active
    case preview
}

final class MenuBarController: NSObject {
    private let settingsStore: AppSettingsStore
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private let headerView = BatteryMenuHeaderView()
    private let detailsView = BatteryMenuDetailsView()
    private let headerItem = NSMenuItem()
    private let detailsItem = NSMenuItem()

    private let pauseItem = NSMenuItem(title: "Pause Alarm", action: #selector(togglePause), keyEquivalent: "")
    private var latestStatus: BatteryStatus?
    private var alarmSummary = "Idle"
    private var alarmVisible = false

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
        ensureStatusItemVisible()
        updateSettings()
    }

    func ensureStatusItemVisible() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            configureMenu()
        }
        statusItem?.length = NSStatusItem.squareLength
        statusItem?.isVisible = true
        statusItem?.button?.isHidden = false
        if let latestStatus {
            updateButton(for: latestStatus)
        } else if let button = statusItem?.button {
            setStatusButton(
                button,
                title: BatteryFormatter.pendingMenuTitle,
                accessibilityLabel: "Battery Panic, loading battery status"
            )
        }
    }

    private func configureMenu() {
        menu.removeAllItems()
        configureMenuItems()
        statusItem?.menu = menu
        statusItem?.isVisible = true
    }

    func update(status: BatteryStatus) {
        latestStatus = status
        updateButton(for: status)
        headerView.update(status: status, settings: settingsStore.snapshot())
        updateDetails()
    }

    func updateSettings() {
        let snapshot = settingsStore.snapshot()
        pauseItem.title = pauseTitle(settings: snapshot)
        headerView.update(status: latestStatus, settings: snapshot)
        updateDetails()
        if let latestStatus {
            updateButton(for: latestStatus)
        }
    }

    func setAlarmVisible(_ visible: Bool, mode: AlarmDisplayMode = .active) {
        alarmVisible = visible
        if visible {
            alarmSummary = mode == .preview ? "Preview running" : "Visible"
        } else {
            alarmSummary = "Idle"
        }
        pauseItem.title = pauseTitle(settings: settingsStore.snapshot())
        updateDetails()
    }

    private func updateButton(for status: BatteryStatus) {
        if let button = statusItem?.button {
            let snapshot = settingsStore.snapshot()
            setStatusButton(
                button,
                title: BatteryFormatter.menuTitle(
                    for: status,
                    threshold: snapshot.thresholdPercentage
                ),
                accessibilityLabel: "Battery Panic, \(BatteryFormatter.longStatus(for: status))"
            )
        }
    }

    private func configureMenuItems() {
        if let button = statusItem?.button {
            button.toolTip = "Battery Panic"
            setStatusButton(
                button,
                title: BatteryFormatter.pendingMenuTitle,
                accessibilityLabel: "Battery Panic, loading battery status"
            )
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

    private func setStatusButton(
        _ button: NSStatusBarButton,
        title: String,
        accessibilityLabel: String
    ) {
        button.image = nil
        button.imagePosition = .noImage
        button.title = "BP"
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        button.contentTintColor = nil
        button.setAccessibilityLabel(accessibilityLabel)
    }

    private func updateDetails() {
        detailsView.update(
            status: latestStatus,
            settings: settingsStore.snapshot(),
            alarmSummary: alarmSummary
        )
    }

    private func pauseTitle(settings: AlarmSettingsSnapshot) -> String {
        if settings.isPaused {
            return "Resume Alarm"
        }
        if alarmVisible {
            return "Stop Alarm for 30 Minutes"
        }
        return "Pause Alarms for 30 Minutes"
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
