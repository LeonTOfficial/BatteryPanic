import AppKit

final class SettingsWindowController: NSWindowController {
    private let settingsStore: AppSettingsStore
    private let loginItemService: LoginItemService

    private let thresholdSlider = NSSlider(value: 10, minValue: 1, maxValue: 50, target: nil, action: nil)
    private let thresholdValueLabel = NSTextField(labelWithString: "10%")
    private let pulseSpeedSlider = NSSlider(value: 1.0, minValue: 0.4, maxValue: 2.4, target: nil, action: nil)
    private let pulseSpeedValueLabel = NSTextField(labelWithString: "1.0x")
    private let pulseIntensitySlider = NSSlider(value: 1.0, minValue: 0.45, maxValue: 1.6, target: nil, action: nil)
    private let pulseIntensityValueLabel = NSTextField(labelWithString: "100%")
    private let previewDurationSlider = NSSlider(value: AppConstants.defaultPreviewDuration, minValue: 3, maxValue: 30, target: nil, action: nil)
    private let previewDurationValueLabel = NSTextField(labelWithString: "8s")
    private let overlayPreviewView = OverlayPreviewView(frame: NSRect(x: 0, y: 0, width: 498, height: 128))
    private let soundPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let pulseCheckbox = NSButton(checkboxWithTitle: "Pulse red overlay", target: nil, action: nil)
    private let soundCheckbox = NSButton(checkboxWithTitle: "Play warning sound", target: nil, action: nil)
    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Start at login", target: nil, action: nil)
    private let pausedCheckbox = NSButton(checkboxWithTitle: "Pause low-battery alarm", target: nil, action: nil)
    private let statusLabel = NSTextField(labelWithString: "Ready")

    var onTestAlarm: (() -> Void)?
    var onTestSound: ((String) -> Void)?
    var onOpenGitHub: (() -> Void)?

    init(settingsStore: AppSettingsStore, loginItemService: LoginItemService) {
        self.settingsStore = settingsStore
        self.loginItemService = loginItemService

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 590, height: 830),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Battery Panic Settings"
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true

        super.init(window: window)
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
        stack.edgeInsets = NSEdgeInsets(top: 28, left: 30, bottom: 26, right: 30)
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(makeHeader())
        stack.addArrangedSubview(makeThresholdSection())
        stack.addArrangedSubview(makeOverlaySection())
        stack.addArrangedSubview(makeSoundSection())
        stack.addArrangedSubview(makeBehaviorSection())
        stack.addArrangedSubview(makeCreditsSection())
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

    private func makeHeader() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 14

        let icon = NSImageView(image: MenuBarIconFactory.image(isLow: true, isPaused: false))
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 38).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 38).isActive = true

        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        let title = NSTextField(labelWithString: "Battery Panic")
        title.font = NSFont.systemFont(ofSize: 26, weight: .bold)

        let subtitle = NSTextField(labelWithString: "A visible red warning when your MacBook battery needs attention.")
        subtitle.textColor = .secondaryLabelColor

        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(subtitle)
        row.addArrangedSubview(icon)
        row.addArrangedSubview(textStack)
        return row
    }

    private func makeThresholdSection() -> NSView {
        thresholdSlider.target = self
        thresholdSlider.action = #selector(thresholdChanged)
        thresholdSlider.numberOfTickMarks = 10
        thresholdSlider.allowsTickMarkValuesOnly = false

        thresholdValueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        thresholdValueLabel.alignment = .right
        thresholdValueLabel.widthAnchor.constraint(equalToConstant: 54).isActive = true

        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.addArrangedSubview(NSTextField(labelWithString: "Warn below"))
        row.addArrangedSubview(thresholdSlider)
        row.addArrangedSubview(thresholdValueLabel)
        thresholdSlider.widthAnchor.constraint(equalToConstant: 300).isActive = true

        return makeSection(
            title: "Battery threshold",
            subtitle: "Default is 10%. The alarm appears only while the Mac is unplugged.",
            content: row
        )
    }

    private func makeBehaviorSection() -> NSView {
        configureCheckboxes()

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.addArrangedSubview(launchAtLoginCheckbox)
        stack.addArrangedSubview(pausedCheckbox)

        return makeSection(
            title: "General",
            subtitle: "Choose how Battery Panic runs in the background.",
            content: stack
        )
    }

    private func makeOverlaySection() -> NSView {
        pulseSpeedSlider.target = self
        pulseSpeedSlider.action = #selector(pulseSpeedChanged)
        pulseIntensitySlider.target = self
        pulseIntensitySlider.action = #selector(pulseIntensityChanged)
        previewDurationSlider.target = self
        previewDurationSlider.action = #selector(previewDurationChanged)
        styleValueLabel(pulseSpeedValueLabel)
        styleValueLabel(pulseIntensityValueLabel)
        styleValueLabel(previewDurationValueLabel)
        overlayPreviewView.heightAnchor.constraint(equalToConstant: 128).isActive = true
        overlayPreviewView.widthAnchor.constraint(equalToConstant: 498).isActive = true

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 11
        stack.addArrangedSubview(overlayPreviewView)
        stack.addArrangedSubview(pulseCheckbox)
        stack.addArrangedSubview(makeSliderRow(title: "Pulse speed", slider: pulseSpeedSlider, valueLabel: pulseSpeedValueLabel))
        stack.addArrangedSubview(makeSliderRow(title: "Pulse intensity", slider: pulseIntensitySlider, valueLabel: pulseIntensityValueLabel))
        stack.addArrangedSubview(makeSliderRow(title: "Preview duration", slider: previewDurationSlider, valueLabel: previewDurationValueLabel))

        return makeSection(
            title: "Pulsing overlay",
            subtitle: "Adjust how the warning breathes. The panel updates live while you move the controls.",
            content: stack
        )
    }

    private func makeSoundSection() -> NSView {
        soundPopup.target = self
        soundPopup.action = #selector(soundSelectionChanged)
        soundPopup.removeAllItems()
        WarningSound.availableSounds.forEach { sound in
            soundPopup.addItem(withTitle: sound.displayName)
            soundPopup.lastItem?.representedObject = sound.name
        }

        let soundRow = NSStackView()
        soundRow.orientation = .horizontal
        soundRow.alignment = .centerY
        soundRow.spacing = 12

        let label = NSTextField(labelWithString: "Warning sound")
        label.widthAnchor.constraint(equalToConstant: 116).isActive = true
        soundPopup.widthAnchor.constraint(equalToConstant: 180).isActive = true

        let testButton = NSButton(title: "Test Sound", target: self, action: #selector(testSound))
        testButton.bezelStyle = .rounded

        soundRow.addArrangedSubview(label)
        soundRow.addArrangedSubview(soundPopup)
        soundRow.addArrangedSubview(testButton)

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.addArrangedSubview(soundCheckbox)
        stack.addArrangedSubview(soundRow)

        return makeSection(
            title: "Audio warning alerts",
            subtitle: "Pick a macOS system sound and test it before relying on it.",
            content: stack
        )
    }

    private func makeCreditsSection() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        let created = NSTextField(labelWithString: "Created by Leon.T")
        created.textColor = .secondaryLabelColor

        let gitHub = NSButton(title: "GitHub: LeonTOfficial", target: self, action: #selector(openGitHub))
        gitHub.isBordered = false
        gitHub.contentTintColor = .linkColor

        row.addArrangedSubview(created)
        row.addArrangedSubview(NSTextField(labelWithString: "•"))
        row.addArrangedSubview(gitHub)
        return row
    }

    private func makeFooter() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        let previewButton = NSButton(title: "Preview Red Screen", target: self, action: #selector(testAlarm))
        previewButton.bezelStyle = .rounded
        previewButton.controlSize = .large

        let doneButton = NSButton(title: "Done", target: self, action: #selector(closeWindow))
        doneButton.bezelStyle = .rounded
        doneButton.controlSize = .large
        doneButton.keyEquivalent = "\r"

        row.addArrangedSubview(statusLabel)
        row.addArrangedSubview(NSView())
        row.addArrangedSubview(previewButton)
        row.addArrangedSubview(doneButton)
        return row
    }

    private func makeSection(title: String, subtitle: String, content: NSView) -> NSView {
        let box = NSBox()
        box.boxType = .custom
        box.cornerRadius = 12
        box.borderWidth = 1
        box.borderColor = NSColor.separatorColor.withAlphaComponent(0.55)
        box.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.68)

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 15, left: 16, bottom: 15, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .semibold)

        let subtitleLabel = NSTextField(labelWithString: subtitle)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.maximumNumberOfLines = 2

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        stack.addArrangedSubview(content)
        box.contentView = stack

        NSLayoutConstraint.activate([
            box.widthAnchor.constraint(equalToConstant: 530),
            stack.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            stack.topAnchor.constraint(equalTo: box.topAnchor),
            stack.bottomAnchor.constraint(equalTo: box.bottomAnchor)
        ])

        return box
    }

    private func configureCheckboxes() {
        pulseCheckbox.target = self
        pulseCheckbox.action = #selector(pulseChanged)
        soundCheckbox.target = self
        soundCheckbox.action = #selector(soundChanged)
        launchAtLoginCheckbox.target = self
        launchAtLoginCheckbox.action = #selector(launchAtLoginChanged)
        pausedCheckbox.target = self
        pausedCheckbox.action = #selector(pausedChanged)
    }

    private func refreshFromSettings() {
        let settings = settingsStore.snapshot()
        thresholdSlider.integerValue = settings.thresholdPercentage
        thresholdValueLabel.stringValue = "\(settings.thresholdPercentage)%"
        pulseSpeedSlider.doubleValue = settings.pulseSpeed
        pulseSpeedValueLabel.stringValue = String(format: "%.1fx", settings.pulseSpeed)
        pulseIntensitySlider.doubleValue = settings.pulseIntensity
        pulseIntensityValueLabel.stringValue = "\(Int(settings.pulseIntensity * 100))%"
        previewDurationSlider.doubleValue = settings.previewDuration
        previewDurationValueLabel.stringValue = "\(Int(settings.previewDuration))s"
        pulseCheckbox.state = settings.pulseEnabled ? .on : .off
        soundCheckbox.state = settings.soundEnabled ? .on : .off
        selectSound(named: settings.selectedSoundName)
        launchAtLoginCheckbox.state = (settings.launchAtLoginEnabled || loginItemService.isEnabled) ? .on : .off
        pausedCheckbox.state = settings.isPaused ? .on : .off
        statusLabel.stringValue = settings.isPaused ? "Alarm paused" : "Ready"
        updateOverlayPreview()
    }

    @objc private func thresholdChanged() {
        let value = thresholdSlider.integerValue.clamped(to: 1...50)
        thresholdValueLabel.stringValue = "\(value)%"
        settingsStore.setThresholdPercentage(value)
        statusLabel.stringValue = "Threshold set to \(value)%"
    }

    @objc private func pulseChanged() {
        settingsStore.setPulseEnabled(pulseCheckbox.state == .on)
        updateOverlayPreview()
        statusLabel.stringValue = pulseCheckbox.state == .on ? "Pulse enabled" : "Pulse disabled"
    }

    @objc private func pulseSpeedChanged() {
        let value = pulseSpeedSlider.doubleValue
        settingsStore.setPulseSpeed(value)
        pulseSpeedValueLabel.stringValue = String(format: "%.1fx", value)
        updateOverlayPreview()
        statusLabel.stringValue = String(format: "Pulse speed set to %.1fx", value)
    }

    @objc private func pulseIntensityChanged() {
        let value = pulseIntensitySlider.doubleValue
        settingsStore.setPulseIntensity(value)
        pulseIntensityValueLabel.stringValue = "\(Int(value * 100))%"
        updateOverlayPreview()
        statusLabel.stringValue = "Pulse intensity set to \(Int(value * 100))%"
    }

    @objc private func previewDurationChanged() {
        let value = previewDurationSlider.doubleValue
        settingsStore.setPreviewDuration(value)
        previewDurationValueLabel.stringValue = "\(Int(value))s"
        statusLabel.stringValue = "Preview duration set to \(Int(value)) seconds"
    }

    @objc private func soundChanged() {
        settingsStore.setSoundEnabled(soundCheckbox.state == .on)
        statusLabel.stringValue = soundCheckbox.state == .on ? "Sound enabled" : "Sound disabled"
    }

    @objc private func soundSelectionChanged() {
        let soundName = selectedSoundName()
        settingsStore.setSelectedSoundName(soundName)
        statusLabel.stringValue = "Sound set to \(WarningSound.sound(named: soundName).displayName)"
    }

    @objc private func testSound() {
        let soundName = selectedSoundName()
        settingsStore.setSelectedSoundName(soundName)
        settingsStore.setSoundEnabled(true)
        soundCheckbox.state = .on
        statusLabel.stringValue = "Playing \(WarningSound.sound(named: soundName).displayName)"
        onTestSound?(soundName)
    }

    @objc private func launchAtLoginChanged() {
        let enabled = launchAtLoginCheckbox.state == .on
        do {
            try loginItemService.setEnabled(enabled)
            settingsStore.setLaunchAtLoginEnabled(enabled)
            statusLabel.stringValue = enabled ? "Starts at login" : "Login start disabled"
        } catch {
            launchAtLoginCheckbox.state = settingsStore.snapshot().launchAtLoginEnabled ? .on : .off
            showError("Could not update login item.", informativeText: error.localizedDescription)
        }
    }

    @objc private func pausedChanged() {
        let paused = pausedCheckbox.state == .on
        settingsStore.setPaused(paused)
        statusLabel.stringValue = paused ? "Alarm paused" : "Ready"
    }

    @objc private func testAlarm() {
        statusLabel.stringValue = "Showing preview for \(Int(settingsStore.snapshot().previewDuration)) seconds"
        onTestAlarm?()
    }

    @objc private func openGitHub() {
        onOpenGitHub?()
    }

    @objc private func closeWindow() {
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

    private func makeSliderRow(title: String, slider: NSSlider, valueLabel: NSTextField) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        let label = NSTextField(labelWithString: title)
        label.widthAnchor.constraint(equalToConstant: 116).isActive = true
        slider.widthAnchor.constraint(equalToConstant: 270).isActive = true
        valueLabel.widthAnchor.constraint(equalToConstant: 54).isActive = true

        row.addArrangedSubview(label)
        row.addArrangedSubview(slider)
        row.addArrangedSubview(valueLabel)
        return row
    }

    private func styleValueLabel(_ label: NSTextField) {
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        label.alignment = .right
    }

    private func selectedSoundName() -> String {
        (soundPopup.selectedItem?.representedObject as? String) ?? WarningSound.defaultSound.name
    }

    private func selectSound(named name: String) {
        let sound = WarningSound.sound(named: name)
        for index in 0..<soundPopup.numberOfItems {
            if soundPopup.item(at: index)?.representedObject as? String == sound.name {
                soundPopup.selectItem(at: index)
                return
            }
        }
        soundPopup.selectItem(at: 0)
    }

    private func updateOverlayPreview() {
        overlayPreviewView.configure(
            pulseEnabled: pulseCheckbox.state == .on,
            pulseSpeed: pulseSpeedSlider.doubleValue,
            pulseIntensity: pulseIntensitySlider.doubleValue
        )
    }
}
