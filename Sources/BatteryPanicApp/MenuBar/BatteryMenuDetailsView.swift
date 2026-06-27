import AppKit

final class BatteryMenuDetailsView: NSView {
    private let batteryValue = NSTextField(labelWithString: "--")
    private let powerValue = NSTextField(labelWithString: "--")
    private let thresholdValue = NSTextField(labelWithString: "--")
    private let alarmValue = NSTextField(labelWithString: "Idle")
    private let overlayValue = NSTextField(labelWithString: "--")
    private let soundValue = NSTextField(labelWithString: "--")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(status: BatteryStatus?, settings: AlarmSettingsSnapshot, alarmSummary: String) {
        if let status, status.hasBattery {
            let appearance = BatteryStatusAppearance.appearance(for: status, threshold: settings.thresholdPercentage)
            batteryValue.stringValue = appearance.title
            powerValue.stringValue = status.isPluggedIn ? "Connected / charging" : "On battery"
        } else {
            batteryValue.stringValue = "No battery detected"
            powerValue.stringValue = "Unknown"
        }

        thresholdValue.stringValue = "\(settings.thresholdPercentage)%"
        alarmValue.stringValue = settings.isPaused ? "Paused in settings" : alarmSummary
        overlayValue.stringValue = String(
            format: "%.1fx pulse · %d%% intensity",
            settings.pulseSpeed,
            Int(settings.pulseIntensity * 100)
        )
        soundValue.stringValue = settings.soundEnabled
            ? WarningSound.sound(named: settings.selectedSoundName).displayName
            : "Off"
    }

    private func setup() {
        frame = NSRect(x: 0, y: 0, width: 318, height: 154)

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 7
        root.edgeInsets = NSEdgeInsets(top: 8, left: 14, bottom: 10, right: 14)
        root.translatesAutoresizingMaskIntoConstraints = false

        root.addArrangedSubview(makeRow(label: "Battery", value: batteryValue))
        root.addArrangedSubview(makeRow(label: "Power", value: powerValue))
        root.addArrangedSubview(makeRow(label: "Threshold", value: thresholdValue))
        root.addArrangedSubview(makeRow(label: "Alarm", value: alarmValue))
        root.addArrangedSubview(makeRow(label: "Overlay", value: overlayValue))
        root.addArrangedSubview(makeRow(label: "Sound", value: soundValue))

        addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor),
            root.trailingAnchor.constraint(equalTo: trailingAnchor),
            root.topAnchor.constraint(equalTo: topAnchor),
            root.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeRow(label: String, value: NSTextField) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 12

        let labelView = NSTextField(labelWithString: label)
        labelView.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        labelView.textColor = .secondaryLabelColor
        labelView.alignment = .right
        labelView.widthAnchor.constraint(equalToConstant: 72).isActive = true

        value.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        value.lineBreakMode = .byTruncatingTail
        value.maximumNumberOfLines = 1
        value.widthAnchor.constraint(equalToConstant: 202).isActive = true

        row.addArrangedSubview(labelView)
        row.addArrangedSubview(value)
        return row
    }
}
