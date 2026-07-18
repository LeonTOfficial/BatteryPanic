import AppKit

enum AlarmDisplayMode {
    case active
    case critical
    case preview
    case chargeReminder
}

final class MenuBarController: NSObject {
    private enum Layout {
        static let minimumStatusItemLength: CGFloat = 58
        static let statusItemPadding: CGFloat = 32
    }

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
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureMenu()
        statusItem?.menu = menu
        statusItem?.isVisible = true
        updateSettings()
    }

    func ensureStatusItemVisible() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            configureMenu()
            statusItem?.menu = menu
        }
        statusItem?.length = NSStatusItem.variableLength
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
            switch mode {
            case .active:
                alarmSummary = "Visible"
            case .critical:
                alarmSummary = "Critical"
            case .preview:
                alarmSummary = "Preview running"
            case .chargeReminder:
                alarmSummary = "Charge reminder"
            }
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
        let percentage = latestStatus?.percentage ?? 80
        let isLow = latestStatus.map { status in
            status.hasBattery && !status.isPluggedIn && status.percentage <= settingsStore.snapshot().thresholdPercentage
        } ?? false
        let appearance = latestStatus.map { status in
            BatteryStatusAppearance.appearance(
                for: status,
                threshold: settingsStore.snapshot().thresholdPercentage
            )
        } ?? BatteryStatusAppearance(
            level: .healthy,
            color: .systemGreen,
            title: "",
            subtitle: "",
            showsBolt: false,
            showsCriticalDot: false
        )
        button.image = MenuBarIconFactory.image(
            appearance: isLow ? BatteryStatusAppearance(
                level: .critical,
                color: .systemRed,
                title: "",
                subtitle: "",
                showsBolt: false,
                showsCriticalDot: true
            ) : appearance,
            percentage: percentage,
            size: NSSize(width: 22, height: 18),
            showsChargingIndicator: false
        )
        button.imagePosition = .imageLeading
        button.title = title
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        button.contentTintColor = nil
        statusItem?.length = preferredStatusItemLength(for: title, font: button.font ?? NSFont.systemFont(ofSize: 12))
        button.setAccessibilityLabel(accessibilityLabel)
    }

    private func preferredStatusItemLength(for title: String, font: NSFont) -> CGFloat {
        let titleWidth = (title as NSString).size(withAttributes: [.font: font]).width
        return max(Layout.minimumStatusItemLength, ceil(titleWidth + Layout.statusItemPadding))
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
