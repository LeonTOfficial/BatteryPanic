import AppKit

final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    private let settingsStore: AppSettingsStore
    private let loginItemService: LoginItemService
    private let launchAtLoginSwitch = NSSwitch()

    var onTestAlarm: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenGitHub: (() -> Void)?

    init(settingsStore: AppSettingsStore, loginItemService: LoginItemService) {
        self.settingsStore = settingsStore
        self.loginItemService = loginItemService

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Battery Panic"
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true

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
        stack.spacing = 18
        stack.edgeInsets = NSEdgeInsets(top: 30, left: 32, bottom: 26, right: 32)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSStackView()
        content.orientation = .horizontal
        content.alignment = .top
        content.spacing = 20
        content.addArrangedSubview(makeIntroPanel())

        let hero = OnboardingHeroView(frame: NSRect(x: 0, y: 0, width: 318, height: 344))
        hero.widthAnchor.constraint(equalToConstant: 318).isActive = true
        hero.heightAnchor.constraint(equalToConstant: 344).isActive = true
        content.addArrangedSubview(hero)

        stack.addArrangedSubview(makeTopBar())
        stack.addArrangedSubview(content)
        stack.addArrangedSubview(makeFooter())

        root.addSubview(stack)
        window.contentView = root

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
    }

    private func makeTopBar() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.widthAnchor.constraint(equalToConstant: 696).isActive = true

        let icon = NSImageView(image: AppIconFactory.image(size: 36))
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 36).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let labels = NSStackView()
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 1

        let title = NSTextField(labelWithString: "Battery Panic")
        title.font = .systemFont(ofSize: 15, weight: .bold)

        let subtitle = NSTextField(labelWithString: "Private low-battery alerts for macOS")
        subtitle.font = .systemFont(ofSize: 12, weight: .regular)
        subtitle.textColor = .secondaryLabelColor

        labels.addArrangedSubview(title)
        labels.addArrangedSubview(subtitle)

        let github = NSButton(title: "GitHub: LeonTOfficial", target: self, action: #selector(openGitHub))
        github.isBordered = false
        github.contentTintColor = .linkColor
        github.font = .systemFont(ofSize: 12, weight: .medium)

        row.addArrangedSubview(icon)
        row.addArrangedSubview(labels)
        row.addArrangedSubview(NSView())
        row.addArrangedSubview(github)
        return row
    }

    private func makeIntroPanel() -> NSView {
        let box = makePanel(width: 358, height: 344)
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 15
        stack.edgeInsets = NSEdgeInsets(top: 22, left: 22, bottom: 20, right: 22)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let eyebrow = makePill("FIRST LAUNCH SETUP")
        let title = makeLabel("Ready before your battery gets critical.", size: 28, weight: .bold, color: .labelColor, lines: 2)
        let subtitle = makeLabel("Battery Panic stays quiet in the menu bar and only shows the red warning when your Mac is unplugged and below your threshold.", size: 13, weight: .regular, color: .secondaryLabelColor, lines: 3)

        stack.addArrangedSubview(eyebrow)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        stack.addArrangedSubview(makeDivider())
        stack.addArrangedSubview(makeInfoRow(symbolName: "battery.25", title: "10% default threshold", body: "Change it later in Settings.", tint: .systemRed))
        stack.addArrangedSubview(makeInfoRow(symbolName: "eye", title: "Safe 4-second preview", body: "Test the overlay without draining the battery.", tint: .systemOrange))
        stack.addArrangedSubview(makeLoginRow())
        stack.addArrangedSubview(makeFeedbackNote())
        box.contentView = stack

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            stack.topAnchor.constraint(equalTo: box.topAnchor),
            stack.bottomAnchor.constraint(equalTo: box.bottomAnchor)
        ])
        return box
    }

    private func makeLoginRow() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        let icon = makeSymbol("power", tint: .systemGreen)
        let text = NSStackView()
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 2
        text.addArrangedSubview(makeLabel("Start at login", size: 13, weight: .semibold, color: .labelColor, lines: 1))
        text.addArrangedSubview(makeLabel("Keep the warning available automatically.", size: 12, weight: .regular, color: .secondaryLabelColor, lines: 1))

        launchAtLoginSwitch.target = self
        launchAtLoginSwitch.action = #selector(launchAtLoginChanged)

        row.addArrangedSubview(icon)
        row.addArrangedSubview(text)
        row.addArrangedSubview(NSView())
        row.addArrangedSubview(launchAtLoginSwitch)
        return row
    }

    private func makeInfoRow(symbolName: String, title: String, body: String, tint: NSColor) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        let text = NSStackView()
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 2
        text.addArrangedSubview(makeLabel(title, size: 13, weight: .semibold, color: .labelColor, lines: 1))
        text.addArrangedSubview(makeLabel(body, size: 12, weight: .regular, color: .secondaryLabelColor, lines: 1))

        row.addArrangedSubview(makeSymbol(symbolName, tint: tint))
        row.addArrangedSubview(text)
        return row
    }

    private func makeFeedbackNote() -> NSView {
        let label = makeLabel("Built by Leon. Feedback or a GitHub star helps this project keep getting better.", size: 12, weight: .medium, color: .secondaryLabelColor, lines: 2)
        label.widthAnchor.constraint(equalToConstant: 300).isActive = true
        return label
    }

    private func makeFooter() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        row.widthAnchor.constraint(equalToConstant: 696).isActive = true

        let credits = makeLabel("Created by Leon.T", size: 12, weight: .medium, color: .secondaryLabelColor, lines: 1)

        let previewButton = NSButton(title: "Preview Alarm", target: self, action: #selector(testAlarm))
        previewButton.bezelStyle = .rounded
        previewButton.controlSize = .large

        let settingsButton = NSButton(title: "Settings", target: self, action: #selector(openSettings))
        settingsButton.bezelStyle = .rounded
        settingsButton.controlSize = .large

        let startButton = NSButton(title: "Start", target: self, action: #selector(completeOnboarding))
        startButton.bezelStyle = .rounded
        startButton.controlSize = .large
        startButton.keyEquivalent = "\r"

        row.addArrangedSubview(credits)
        row.addArrangedSubview(NSView())
        row.addArrangedSubview(previewButton)
        row.addArrangedSubview(settingsButton)
        row.addArrangedSubview(startButton)
        return row
    }

    private func makePanel(width: CGFloat, height: CGFloat) -> NSBox {
        let box = NSBox()
        box.boxType = .custom
        box.cornerRadius = 22
        box.borderWidth = 1
        box.borderColor = NSColor.separatorColor.withAlphaComponent(0.45)
        box.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.70)
        box.widthAnchor.constraint(equalToConstant: width).isActive = true
        box.heightAnchor.constraint(equalToConstant: height).isActive = true
        return box
    }

    private func makePill(_ text: String) -> NSView {
        let label = makeLabel(text, size: 10, weight: .black, color: .systemRed, lines: 1)
        let box = NSBox()
        box.boxType = .custom
        box.cornerRadius = 11
        box.borderWidth = 1
        box.borderColor = NSColor.systemRed.withAlphaComponent(0.28)
        box.fillColor = NSColor.systemRed.withAlphaComponent(0.10)
        box.contentView = label
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: box.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -4)
        ])
        return box
    }

    private func makeDivider() -> NSView {
        let divider = NSBox()
        divider.boxType = .separator
        divider.widthAnchor.constraint(equalToConstant: 310).isActive = true
        return divider
    }

    private func makeSymbol(_ name: String, tint: NSColor) -> NSView {
        let holder = NSBox()
        holder.boxType = .custom
        holder.cornerRadius = 10
        holder.borderWidth = 0
        holder.fillColor = tint.withAlphaComponent(0.12)
        holder.widthAnchor.constraint(equalToConstant: 34).isActive = true
        holder.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let image = NSImageView(image: NSImage(systemSymbolName: name, accessibilityDescription: nil) ?? NSImage())
        image.contentTintColor = tint
        image.imageScaling = .scaleProportionallyUpOrDown
        image.translatesAutoresizingMaskIntoConstraints = false
        holder.addSubview(image)
        NSLayoutConstraint.activate([
            image.centerXAnchor.constraint(equalTo: holder.centerXAnchor),
            image.centerYAnchor.constraint(equalTo: holder.centerYAnchor),
            image.widthAnchor.constraint(equalToConstant: 17),
            image.heightAnchor.constraint(equalToConstant: 17)
        ])
        return holder
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, lines: Int) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = lines
        return label
    }

    private func refreshFromSettings() {
        let enabled = loginItemService.isEnabled || settingsStore.snapshot().launchAtLoginEnabled
        launchAtLoginSwitch.state = enabled ? .on : .off
    }

    @objc private func launchAtLoginChanged() {
        let enabled = launchAtLoginSwitch.state == .on
        do {
            try loginItemService.setEnabled(enabled)
            settingsStore.setLaunchAtLoginEnabled(enabled)
        } catch {
            launchAtLoginSwitch.state = settingsStore.snapshot().launchAtLoginEnabled ? .on : .off
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
