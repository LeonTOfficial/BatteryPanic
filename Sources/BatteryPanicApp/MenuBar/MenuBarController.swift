import AppKit
import SwiftUI

enum AlarmDisplayMode {
    case active
    case critical
    case preview
    case chargeReminder
}

enum MenuBarSnoozeIndicatorPolicy {
    static func shouldHighlight(status: BatteryStatus, settings: AlarmSettingsSnapshot) -> Bool {
        settings.isPaused
            && status.hasBattery
            && !status.isPluggedIn
            && status.percentage <= settings.thresholdPercentage
    }
}

final class MenuBarController: NSObject {
    private enum Layout {
        static let minimumStatusItemLength: CGFloat = 58
        static let statusItemPadding: CGFloat = 32
        static let dashboardWidth: CGFloat = 426
        static let dashboardHeight: CGFloat = 376
        static let pausedDashboardHeight: CGFloat = 440
    }

    private let settingsStore: AppSettingsStore
    private let dashboardModel: BatteryDashboardViewModel
    private let dashboardView: NSHostingView<BatteryDashboardView>
    private let reduceMotionEnabled: () -> Bool
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private let dashboardItem = NSMenuItem()
    private let pauseItem = NSMenuItem(title: "Pause alarms for 30 minutes", action: #selector(togglePause), keyEquivalent: "")
    private var latestStatus: BatteryStatus?
    private var alarmVisible = false
    private var percentagePulseTimer: Timer?
    private var percentagePulseStartedAt = Date()
    private var percentagePulseUntil: Date?
    private var historyRangeSelectionCommitted = false

    var onOpenSettings: (() -> Void)?
    var onOpenWelcome: (() -> Void)?
    var onTestAlarm: (() -> Void)?
    var onTogglePause: (() -> Void)?
    var onOpenGitHub: (() -> Void)?
    var onQuit: (() -> Void)?
    var onConfigureUpdaterMenuItem: ((NSMenuItem) -> Void)?

    var isPercentagePulseActiveForTesting: Bool {
        percentagePulseTimer != nil
    }

    var statusTitleForTesting: NSAttributedString? {
        statusItem?.button?.attributedTitle
    }

    var menuKeyEquivalentsForTesting: [String] {
        menu.items
            .filter { !$0.isSeparatorItem && $0 !== dashboardItem }
            .map(\.keyEquivalent)
    }

    init(
        settingsStore: AppSettingsStore,
        historyStore: BatteryHistoryStore,
        dashboardDefaults: UserDefaults = .standard,
        reduceMotionEnabled: @escaping () -> Bool = {
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        }
    ) {
        self.settingsStore = settingsStore
        self.reduceMotionEnabled = reduceMotionEnabled
        let model = BatteryDashboardViewModel(
            settings: settingsStore.snapshot(),
            historyStore: historyStore,
            defaults: dashboardDefaults
        )
        dashboardModel = model
        dashboardView = NSHostingView(rootView: BatteryDashboardView(model: model))
        super.init()

        model.onResumeAlarm = { [weak self] in
            self?.menu.cancelTracking()
            self?.onTogglePause?()
        }
        model.onChooseHistoryRange = { [weak self] in
            self?.presentHistoryRangeMenu()
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(accessibilityDisplayOptionsChanged),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
    }

    deinit {
        percentagePulseTimer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func start() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureMenu()
        statusItem?.menu = menu
        statusItem?.isVisible = true
        updateSettings()
    }

    func stop() {
        stopPercentagePulse()
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
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
            setPendingStatusButton(button)
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
        let settings = settingsStore.snapshot()
        dashboardModel.update(status: status, settings: settings)
        resizeDashboard(for: settings)
        updateButton(for: status)
        updatePauseItem(settings: settings)
    }

    func updateSettings() {
        let snapshot = settingsStore.snapshot()
        dashboardModel.update(status: latestStatus, settings: snapshot)
        resizeDashboard(for: snapshot)
        updatePauseItem(settings: snapshot)
        if let latestStatus {
            updateButton(for: latestStatus)
        }
    }

    func setAlarmVisible(_ visible: Bool, mode: AlarmDisplayMode = .active) {
        alarmVisible = visible
        updatePauseItem(settings: settingsStore.snapshot())
    }

    private func updateButton(for status: BatteryStatus) {
        guard let button = statusItem?.button else { return }
        let snapshot = settingsStore.snapshot()
        let isLow = status.hasBattery
            && !status.isPluggedIn
            && status.percentage <= snapshot.thresholdPercentage
        let appearance = BatteryStatusAppearance.appearance(
            for: status,
            threshold: snapshot.thresholdPercentage
        )
        let iconAppearance = isLow
            ? BatteryStatusAppearance(
                level: .critical,
                color: .systemRed,
                title: "",
                subtitle: "",
                showsBolt: false,
                showsCriticalDot: true
            )
            : appearance

        button.image = MenuBarIconFactory.image(
            appearance: iconAppearance,
            percentage: status.percentage,
            size: NSSize(width: 22, height: 18),
            showsChargingIndicator: false
        )
        button.imagePosition = .imageLeading
        button.contentTintColor = nil

        if MenuBarSnoozeIndicatorPolicy.shouldHighlight(status: status, settings: snapshot) {
            percentagePulseUntil = snapshot.pauseUntil
            let title = "\(status.percentage)%"
            let accessibilityLabel = "Battery Panic, alarm paused, \(BatteryFormatter.longStatus(for: status))"
            if reduceMotionEnabled() {
                stopPercentagePulse(clearDeadline: false)
                setStatusTitle(
                    button,
                    title: title,
                    color: .systemRed,
                    accessibilityLabel: accessibilityLabel
                )
            } else {
                startPercentagePulse()
                renderPercentagePulse(on: button, status: status)
            }
            return
        }

        stopPercentagePulse()
        setStatusTitle(
            button,
            title: BatteryFormatter.menuTitle(
                for: status,
                threshold: snapshot.thresholdPercentage
            ),
            color: nil,
            accessibilityLabel: "Battery Panic, \(BatteryFormatter.longStatus(for: status))"
        )
    }

    private func configureMenuItems() {
        if let button = statusItem?.button {
            button.toolTip = "Battery Panic"
            setPendingStatusButton(button)
        }

        dashboardItem.view = dashboardView
        resizeDashboard(for: settingsStore.snapshot())
        pauseItem.target = self
        removeKeyEquivalent(from: pauseItem)
        configureSymbol("pause.circle", for: pauseItem, description: "Pause alarms")

        let testItem = NSMenuItem(title: "Preview alarm", action: #selector(testAlarm), keyEquivalent: "")
        testItem.target = self
        removeKeyEquivalent(from: testItem)
        configureSymbol("bell", for: testItem, description: "Preview alarm")

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        removeKeyEquivalent(from: settingsItem)
        configureSymbol("gearshape", for: settingsItem, description: "Settings")

        let updateItem = NSMenuItem(title: "Check for Updates…", action: nil, keyEquivalent: "")
        configureSymbol("arrow.triangle.2.circlepath", for: updateItem, description: "Check for updates")
        onConfigureUpdaterMenuItem?(updateItem)
        removeKeyEquivalent(from: updateItem)

        let quitItem = NSMenuItem(title: "Quit Battery Panic", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        removeKeyEquivalent(from: quitItem)
        configureSymbol("power", for: quitItem, description: "Quit Battery Panic")

        menu.addItem(dashboardItem)
        menu.addItem(testItem)
        menu.addItem(pauseItem)
        menu.addItem(settingsItem)
        menu.addItem(updateItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
    }

    private func removeKeyEquivalent(from item: NSMenuItem) {
        item.keyEquivalent = ""
        item.keyEquivalentModifierMask = []
    }

    private func presentHistoryRangeMenu() {
        let anchor = NSEvent.mouseLocation
        menu.cancelTrackingWithoutAnimation()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let rangeMenu = NSMenu(title: "History range")
            rangeMenu.autoenablesItems = false
            var selectedItem: NSMenuItem?

            for (index, range) in BatteryHistoryRange.allCases.enumerated() {
                let item = NSMenuItem(
                    title: range.menuTitle,
                    action: #selector(self.selectHistoryRange(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.tag = index
                item.state = range == dashboardModel.selectedRange ? .on : .off
                removeKeyEquivalent(from: item)
                rangeMenu.addItem(item)
                if item.state == .on {
                    selectedItem = item
                }
            }

            historyRangeSelectionCommitted = false
            rangeMenu.popUp(positioning: selectedItem, at: anchor, in: nil)
            guard historyRangeSelectionCommitted else { return }
            DispatchQueue.main.async { [weak self] in
                self?.statusItem?.button?.performClick(nil)
            }
        }
    }

    @objc private func selectHistoryRange(_ sender: NSMenuItem) {
        guard BatteryHistoryRange.allCases.indices.contains(sender.tag) else { return }
        dashboardModel.selectedRange = BatteryHistoryRange.allCases[sender.tag]
        historyRangeSelectionCommitted = true
    }

    private func configureSymbol(_ name: String, for item: NSMenuItem, description: String) {
        item.indentationLevel = 2
        item.image = alignedMenuSymbol(named: name, description: description)
        styleActionTitle(for: item)
    }

    private func styleActionTitle(for item: NSMenuItem) {
        item.attributedTitle = NSAttributedString(
            string: item.title,
            attributes: [.font: NSFont.systemFont(ofSize: 15, weight: .regular)]
        )
    }

    private func alignedMenuSymbol(named name: String, description: String) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(
            pointSize: 17,
            weight: .regular,
            scale: .medium
        )
        guard let symbol = NSImage(
            systemSymbolName: name,
            accessibilityDescription: description
        )?.withSymbolConfiguration(configuration) else {
            return nil
        }

        // AppKit gives menu items only the intrinsic SF Symbol width, so icons
        // with different silhouettes otherwise make their labels jump sideways.
        // A fixed 18 pt symbol cell plus a transparent 14 pt text gutter keeps
        // every native action on the same visual column as the paused banner.
        let symbolCell = NSSize(width: 18, height: 18)
        let canvas = NSImage(size: NSSize(width: 32, height: 28))
        canvas.lockFocus()
        let scale = min(
            symbolCell.width / max(symbol.size.width, 1),
            symbolCell.height / max(symbol.size.height, 1)
        )
        let drawSize = NSSize(width: symbol.size.width * scale, height: symbol.size.height * scale)
        let drawRect = NSRect(
            x: (symbolCell.width - drawSize.width) / 2,
            y: (canvas.size.height - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        symbol.draw(in: drawRect)
        canvas.unlockFocus()
        canvas.isTemplate = true
        canvas.accessibilityDescription = description
        return canvas
    }

    private func resizeDashboard(for settings: AlarmSettingsSnapshot) {
        dashboardView.frame = NSRect(
            x: 0,
            y: 0,
            width: Layout.dashboardWidth,
            height: settings.isPaused ? Layout.pausedDashboardHeight : Layout.dashboardHeight
        )
    }

    private func setPendingStatusButton(_ button: NSStatusBarButton) {
        setStatusTitle(
            button,
            title: BatteryFormatter.pendingMenuTitle,
            color: nil,
            accessibilityLabel: "Battery Panic, loading battery status"
        )
    }

    private func setStatusTitle(
        _ button: NSStatusBarButton,
        title: String,
        color: NSColor?,
        accessibilityLabel: String
    ) {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        var attributes: [NSAttributedString.Key: Any] = [.font: font]
        if let color {
            attributes[.foregroundColor] = color
        }
        button.attributedTitle = NSAttributedString(string: title, attributes: attributes)
        button.font = font
        statusItem?.length = preferredStatusItemLength(for: title, font: font)
        button.setAccessibilityLabel(accessibilityLabel)
    }

    private func preferredStatusItemLength(for title: String, font: NSFont) -> CGFloat {
        let titleWidth = (title as NSString).size(withAttributes: [.font: font]).width
        return max(Layout.minimumStatusItemLength, ceil(titleWidth + Layout.statusItemPadding))
    }

    private func updatePauseItem(settings: AlarmSettingsSnapshot) {
        pauseItem.isHidden = settings.isPaused
        pauseItem.title = alarmVisible
            ? "Stop alarm for 30 minutes"
            : "Pause alarms for 30 minutes"
        styleActionTitle(for: pauseItem)
    }

    private func startPercentagePulse() {
        guard percentagePulseTimer == nil else { return }
        percentagePulseStartedAt = Date()
        let timer = Timer(timeInterval: 1.0 / 12.0, repeats: true) { [weak self] _ in
            self?.tickPercentagePulse()
        }
        RunLoop.main.add(timer, forMode: .common)
        percentagePulseTimer = timer
    }

    private func stopPercentagePulse(clearDeadline: Bool = true) {
        percentagePulseTimer?.invalidate()
        percentagePulseTimer = nil
        if clearDeadline {
            percentagePulseUntil = nil
        }
    }

    private func tickPercentagePulse() {
        if let percentagePulseUntil, percentagePulseUntil <= Date() {
            stopPercentagePulse()
            updateSettings()
            return
        }
        guard
            !reduceMotionEnabled(),
            let status = latestStatus,
            let button = statusItem?.button
        else {
            stopPercentagePulse(clearDeadline: false)
            if let latestStatus {
                updateButton(for: latestStatus)
            }
            return
        }
        renderPercentagePulse(on: button, status: status)
    }

    private func renderPercentagePulse(on button: NSStatusBarButton, status: BatteryStatus) {
        let elapsed = Date().timeIntervalSince(percentagePulseStartedAt)
        let wave = (sin(elapsed * .pi * 2 / 1.4) + 1) / 2
        let alpha = 0.36 + (wave * 0.64)
        setStatusTitle(
            button,
            title: "\(status.percentage)%",
            color: NSColor.systemRed.withAlphaComponent(alpha),
            accessibilityLabel: "Battery Panic, alarm paused, \(BatteryFormatter.longStatus(for: status))"
        )
    }

    @objc private func accessibilityDisplayOptionsChanged() {
        guard let latestStatus else { return }
        updateButton(for: latestStatus)
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func testAlarm() {
        onTestAlarm?()
    }

    @objc private func togglePause() {
        onTogglePause?()
    }

    @objc private func quit() {
        onQuit?()
    }
}
