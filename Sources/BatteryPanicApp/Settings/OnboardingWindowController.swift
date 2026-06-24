import AppKit

final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    private let settingsStore: AppSettingsStore
    private let loginItemService: LoginItemService
    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Start Battery Panic at login", target: nil, action: nil)

    var onTestAlarm: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenGitHub: (() -> Void)?

    init(settingsStore: AppSettingsStore, loginItemService: LoginItemService) {
        self.settingsStore = settingsStore
        self.loginItemService = loginItemService

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 470),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Battery Panic"
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self
        setupUI()
        refreshFromSettings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        refreshFromSettings()
        window?.center()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        settingsStore.setHasCompletedOnboarding(true)
    }

    private func setupUI() {
        guard let window else { return }

        let root = NSVisualEffectView()
        root.material = .windowBackground
        root.blendingMode = .behindWindow
        root.state = .active
        root.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 20
        stack.edgeInsets = NSEdgeInsets(top: 28, left: 30, bottom: 26, right: 30)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let header = makeHeader()
        let featureRow = makeFeatureRow()
        let setupCard = makeSetupCard()
        let credits = makeCreditsRow()
        let buttons = makeButtons()

        stack.addArrangedSubview(header)
        stack.addArrangedSubview(featureRow)
        stack.addArrangedSubview(setupCard)
        stack.addArrangedSubview(credits)
        stack.addArrangedSubview(NSView())
        stack.addArrangedSubview(buttons)

        root.addSubview(stack)
        window.contentView = root

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
    }

    private func makeHeader() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 16

        let icon = NSImageView(image: MenuBarIconFactory.image(isLow: true, isPaused: false))
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 48).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 5

        let title = NSTextField(labelWithString: "Battery Panic is ready")
        title.font = NSFont.systemFont(ofSize: 28, weight: .bold)

        let subtitle = NSTextField(labelWithString: "A red screen warning appears when your MacBook drops below your chosen battery level.")
        subtitle.textColor = .secondaryLabelColor
        subtitle.lineBreakMode = .byWordWrapping
        subtitle.maximumNumberOfLines = 2

        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(subtitle)

        row.addArrangedSubview(icon)
        row.addArrangedSubview(textStack)
        return row
    }

    private func makeFeatureRow() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .top
        row.distribution = .fillEqually
        row.spacing = 12

        row.addArrangedSubview(makeFeatureCard(title: "10% default", body: "Change the threshold anytime."))
        row.addArrangedSubview(makeFeatureCard(title: "Red preview", body: "Test the full-screen warning now."))
        row.addArrangedSubview(makeFeatureCard(title: "Menu bar app", body: "Runs quietly in the background."))

        return row
    }

    private func makeFeatureCard(title: String, body: String) -> NSView {
        let box = NSBox()
        box.boxType = .custom
        box.cornerRadius = 10
        box.borderWidth = 1
        box.borderColor = NSColor.separatorColor.withAlphaComponent(0.55)
        box.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.75)

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 5
        stack.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)

        let bodyLabel = NSTextField(labelWithString: body)
        bodyLabel.font = NSFont.systemFont(ofSize: 12)
        bodyLabel.textColor = .secondaryLabelColor
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.maximumNumberOfLines = 2

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(bodyLabel)
        box.contentView = stack

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            stack.topAnchor.constraint(equalTo: box.topAnchor),
            stack.bottomAnchor.constraint(equalTo: box.bottomAnchor)
        ])

        return box
    }

    private func makeSetupCard() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10

        let title = NSTextField(labelWithString: "Quick setup")
        title.font = NSFont.systemFont(ofSize: 16, weight: .semibold)

        launchAtLoginCheckbox.target = self
        launchAtLoginCheckbox.action = #selector(launchAtLoginChanged)

        let note = NSTextField(labelWithString: "Current default: warn at 10% battery while unplugged.")
        note.textColor = .secondaryLabelColor

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(launchAtLoginCheckbox)
        stack.addArrangedSubview(note)
        return stack
    }

    private func makeButtons() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10

        let previewButton = NSButton(title: "Preview Red Screen", target: self, action: #selector(testAlarm))
        previewButton.bezelStyle = .rounded
        previewButton.controlSize = .large

        let settingsButton = NSButton(title: "Open Settings", target: self, action: #selector(openSettings))
        settingsButton.bezelStyle = .rounded
        settingsButton.controlSize = .large

        let startButton = NSButton(title: "Start Using Battery Panic", target: self, action: #selector(completeOnboarding))
        startButton.bezelStyle = .rounded
        startButton.controlSize = .large
        startButton.keyEquivalent = "\r"

        row.addArrangedSubview(previewButton)
        row.addArrangedSubview(settingsButton)
        row.addArrangedSubview(NSView())
        row.addArrangedSubview(startButton)
        return row
    }

    private func makeCreditsRow() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        let created = NSTextField(labelWithString: "Created by Leon.T")
        created.textColor = .secondaryLabelColor

        let github = NSButton(title: "GitHub: LeonTOfficial", target: self, action: #selector(openGitHub))
        github.isBordered = false
        github.contentTintColor = .linkColor

        row.addArrangedSubview(created)
        row.addArrangedSubview(NSTextField(labelWithString: "•"))
        row.addArrangedSubview(github)
        return row
    }

    private func refreshFromSettings() {
        let enabled = loginItemService.isEnabled || settingsStore.snapshot().launchAtLoginEnabled
        launchAtLoginCheckbox.state = enabled ? .on : .off
    }

    @objc private func launchAtLoginChanged() {
        let enabled = launchAtLoginCheckbox.state == .on
        do {
            try loginItemService.setEnabled(enabled)
            settingsStore.setLaunchAtLoginEnabled(enabled)
        } catch {
            launchAtLoginCheckbox.state = settingsStore.snapshot().launchAtLoginEnabled ? .on : .off
            showError("Could not update login item.", informativeText: error.localizedDescription)
        }
    }

    @objc private func testAlarm() {
        onTestAlarm?()
    }

    @objc private func openSettings() {
        settingsStore.setHasCompletedOnboarding(true)
        close()
        onOpenSettings?()
    }

    @objc private func openGitHub() {
        onOpenGitHub?()
    }

    @objc private func completeOnboarding() {
        settingsStore.setHasCompletedOnboarding(true)
        close()
    }

    private func showError(_ messageText: String, informativeText: String) {
        guard let window else { return }
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.alertStyle = .warning
        alert.beginSheetModal(for: window)
    }
}
