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
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 620),
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
        stack.spacing = 22
        stack.edgeInsets = NSEdgeInsets(top: 34, left: 38, bottom: 28, right: 38)
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(makeTopBar())
        stack.addArrangedSubview(makeHeroSection())
        stack.addArrangedSubview(makeSetupSection())
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
        row.widthAnchor.constraint(equalToConstant: 804).isActive = true

        let icon = NSImageView(image: AppIconFactory.image(size: 38))
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 38).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 38).isActive = true

        let labels = NSStackView()
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 2

        let title = makeLabel("Battery Panic", size: 16, weight: .bold, color: .labelColor, lines: 1)
        let subtitle = makeLabel("Private low-battery alerts for macOS", size: 12, weight: .regular, color: .secondaryLabelColor, lines: 1)
        labels.addArrangedSubview(title)
        labels.addArrangedSubview(subtitle)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let github = NSButton(title: "GitHub: LeonTOfficial", target: self, action: #selector(openGitHub))
        github.isBordered = false
        github.contentTintColor = .linkColor
        github.font = .systemFont(ofSize: 12, weight: .medium)

        row.addArrangedSubview(icon)
        row.addArrangedSubview(labels)
        row.addArrangedSubview(spacer)
        row.addArrangedSubview(github)
        return row
    }

    private func makeHeroSection() -> NSView {
        let card = makeCard(width: 804, height: 296, radius: 26)

        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 30
        row.edgeInsets = NSEdgeInsets(top: 28, left: 30, bottom: 28, right: 30)
        row.translatesAutoresizingMaskIntoConstraints = false

        let copy = NSStackView()
        copy.orientation = .vertical
        copy.alignment = .leading
        copy.spacing = 16
        copy.widthAnchor.constraint(equalToConstant: 402).isActive = true

        copy.addArrangedSubview(makePill("FIRST LAUNCH SETUP"))
        copy.addArrangedSubview(makeLabel("Your Mac should warn you before it disappears.", size: 32, weight: .bold, color: .labelColor, lines: 2))
        copy.addArrangedSubview(makeLabel("Battery Panic stays quiet in the menu bar, then shows a strong red overlay when the battery falls below your threshold while unplugged.", size: 14, weight: .regular, color: .secondaryLabelColor, lines: 3))
        copy.addArrangedSubview(makeFeedbackNote())

        let hero = OnboardingHeroView(frame: NSRect(x: 0, y: 0, width: 320, height: 238))
        hero.widthAnchor.constraint(equalToConstant: 320).isActive = true
        hero.heightAnchor.constraint(equalToConstant: 238).isActive = true

        row.addArrangedSubview(copy)
        row.addArrangedSubview(hero)
        card.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            row.topAnchor.constraint(equalTo: card.topAnchor),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    private func makeSetupSection() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = 14
        row.widthAnchor.constraint(equalToConstant: 804).isActive = true

        row.addArrangedSubview(makeInfoTile(symbolName: "battery.25", title: "10% default threshold", body: "Change it any time in Settings.", tint: .systemRed))
        row.addArrangedSubview(makeInfoTile(symbolName: "eye", title: "4-second preview", body: "Test the alert without draining your battery.", tint: .systemOrange))
        row.addArrangedSubview(makeLoginTile())
        return row
    }

    private func makeLoginTile() -> NSView {
        let tile = makeInfoTile(symbolName: "power", title: "Start at login", body: "Keep Battery Panic ready automatically.", tint: .systemGreen)
        launchAtLoginSwitch.target = self
        launchAtLoginSwitch.action = #selector(launchAtLoginChanged)
        launchAtLoginSwitch.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(launchAtLoginSwitch)
        NSLayoutConstraint.activate([
            launchAtLoginSwitch.trailingAnchor.constraint(equalTo: tile.trailingAnchor, constant: -18),
            launchAtLoginSwitch.centerYAnchor.constraint(equalTo: tile.centerYAnchor)
        ])
        return tile
    }

    private func makeInfoTile(symbolName: String, title: String, body: String, tint: NSColor) -> NSView {
        let card = makeCard(width: 258, height: 118, radius: 18)

        let icon = makeSymbol(symbolName, tint: tint)
        icon.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(icon)

        let labels = NSStackView()
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 4
        labels.translatesAutoresizingMaskIntoConstraints = false
        labels.addArrangedSubview(makeLabel(title, size: 13, weight: .semibold, color: .labelColor, lines: 2))
        labels.addArrangedSubview(makeLabel(body, size: 12, weight: .regular, color: .secondaryLabelColor, lines: 2))
        card.addSubview(labels)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            labels.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            labels.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            labels.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        return card
    }

    private func makeFooter() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        row.widthAnchor.constraint(equalToConstant: 804).isActive = true

        let credits = makeLabel("Created by Leon.T", size: 12, weight: .medium, color: .secondaryLabelColor, lines: 1)
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

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
        row.addArrangedSubview(spacer)
        row.addArrangedSubview(previewButton)
        row.addArrangedSubview(settingsButton)
        row.addArrangedSubview(startButton)
        return row
    }

    private func makeCard(width: CGFloat, height: CGFloat, radius: CGFloat) -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.cornerRadius = radius
        card.layer?.borderWidth = 1
        card.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.38).cgColor
        card.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.62).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        card.widthAnchor.constraint(equalToConstant: width).isActive = true
        card.heightAnchor.constraint(equalToConstant: height).isActive = true
        return card
    }

    private func makePill(_ text: String) -> NSView {
        let label = makeLabel(text, size: 10, weight: .black, color: .systemRed, lines: 1)
        label.translatesAutoresizingMaskIntoConstraints = false

        let holder = NSView()
        holder.wantsLayer = true
        holder.layer?.cornerRadius = 11
        holder.layer?.borderWidth = 1
        holder.layer?.borderColor = NSColor.systemRed.withAlphaComponent(0.25).cgColor
        holder.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.09).cgColor
        holder.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: holder.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: holder.trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: holder.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: holder.bottomAnchor, constant: -4)
        ])
        return holder
    }

    private func makeFeedbackNote() -> NSView {
        let label = makeLabel("Built by Leon. Feedback or a GitHub star helps this project keep getting better.", size: 12, weight: .medium, color: .secondaryLabelColor, lines: 2)
        label.widthAnchor.constraint(equalToConstant: 390).isActive = true
        return label
    }

    private func makeSymbol(_ name: String, tint: NSColor) -> NSView {
        let holder = NSView()
        holder.wantsLayer = true
        holder.layer?.cornerRadius = 10
        holder.layer?.backgroundColor = tint.withAlphaComponent(0.12).cgColor
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
