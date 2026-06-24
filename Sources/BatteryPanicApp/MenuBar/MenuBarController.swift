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
    private let headerItem = NSMenuItem()

    private let statusLineItem = NSMenuItem(title: "Battery: --", action: nil, keyEquivalent: "")
    private let thresholdItem = NSMenuItem(title: "Threshold: 10%", action: nil, keyEquivalent: "")
    private let alarmStateItem = NSMenuItem(title: "Alarm: idle", action: nil, keyEquivalent: "")
    private let pauseItem = NSMenuItem(title: "Pause Alarm", action: #selector(togglePause), keyEquivalent: "")
    private var latestStatus: BatteryStatus?

    var onOpenSettings: (() -> Void)?
    var onOpenWelcome: (() -> Void)?
    var onTestAlarm: (() -> Void)?
    var onTogglePause: (() -> Void)?
    var onOpenGitHub: (() -> Void)?
    var onQuit: (() -> Void)?

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
        statusLineItem.title = "Battery: \(BatteryFormatter.longStatus(for: status))"
    }

    func updateSettings() {
        let snapshot = settingsStore.snapshot()
        thresholdItem.title = "Threshold: \(snapshot.thresholdPercentage)%"
        pauseItem.title = snapshot.isPaused ? "Resume Alarm" : "Pause Alarm"
        headerView.update(status: latestStatus, settings: snapshot)
        if let latestStatus {
            updateButton(for: latestStatus)
        }
    }

    func setAlarmVisible(_ visible: Bool, mode: AlarmDisplayMode = .active) {
        if visible {
            alarmStateItem.title = mode == .preview ? "Alarm: preview" : "Alarm: visible"
        } else {
            alarmStateItem.title = "Alarm: idle"
        }
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
        headerView.onOpenGitHub = { [weak self] in
            self?.onOpenGitHub?()
        }
        statusLineItem.isEnabled = false
        thresholdItem.isEnabled = false
        alarmStateItem.isEnabled = false
        pauseItem.target = self

        let testItem = NSMenuItem(title: "Preview Red Screen", action: #selector(testAlarm), keyEquivalent: "t")
        testItem.target = self

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self

        let welcomeItem = NSMenuItem(title: "Welcome & Setup...", action: #selector(openWelcome), keyEquivalent: "")
        welcomeItem.target = self

        let creatorItem = NSMenuItem(title: "Created by Leon.T", action: nil, keyEquivalent: "")
        creatorItem.isEnabled = false

        let gitHubItem = NSMenuItem(title: "GitHub: LeonTOfficial", action: #selector(openGitHub), keyEquivalent: "")
        gitHubItem.target = self

        let quitItem = NSMenuItem(title: "Quit Battery Panic", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self

        menu.addItem(headerItem)
        menu.addItem(.separator())
        menu.addItem(statusLineItem)
        menu.addItem(thresholdItem)
        menu.addItem(alarmStateItem)
        menu.addItem(.separator())
        menu.addItem(testItem)
        menu.addItem(pauseItem)
        menu.addItem(settingsItem)
        menu.addItem(welcomeItem)
        menu.addItem(.separator())
        menu.addItem(creatorItem)
        menu.addItem(gitHubItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
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
