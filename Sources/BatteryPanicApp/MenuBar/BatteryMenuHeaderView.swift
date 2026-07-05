import AppKit

final class BatteryMenuHeaderView: NSView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "Battery Panic")
    private let subtitleLabel = NSTextField(labelWithString: "Waiting for battery status...")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(status: BatteryStatus?, settings: AlarmSettingsSnapshot) {
        let fallback = BatteryStatus.noBattery()
        let status = status ?? fallback
        let appearance = BatteryStatusAppearance.appearance(
            for: status,
            threshold: settings.thresholdPercentage
        )
        iconView.image = MenuBarIconFactory.image(appearance: appearance, percentage: status.percentage)
        titleLabel.stringValue = appearance.title
        let chargeText = settings.chargeReminderEnabled
            ? "Charge: \(settings.chargeReminderThresholdPercentage)%"
            : "Charge: off"
        subtitleLabel.stringValue = "\(appearance.subtitle) Low: \(settings.thresholdPercentage)% - \(chargeText)"
    }

    private func setup() {
        frame = NSRect(x: 0, y: 0, width: 344, height: 88)

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 8
        root.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 14, right: 18)
        root.translatesAutoresizingMaskIntoConstraints = false

        let topRow = NSStackView()
        topRow.orientation = .horizontal
        topRow.alignment = .centerY
        topRow.spacing = 10

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let labels = NSStackView()
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 2

        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        subtitleLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.maximumNumberOfLines = 1

        labels.addArrangedSubview(titleLabel)
        labels.addArrangedSubview(subtitleLabel)
        topRow.addArrangedSubview(iconView)
        topRow.addArrangedSubview(labels)

        root.addArrangedSubview(topRow)
        addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor),
            root.trailingAnchor.constraint(equalTo: trailingAnchor),
            root.topAnchor.constraint(equalTo: topAnchor),
            root.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

}
