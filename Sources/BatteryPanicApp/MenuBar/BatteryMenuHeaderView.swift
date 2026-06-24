import AppKit

final class BatteryMenuHeaderView: NSView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "Battery Panic")
    private let subtitleLabel = NSTextField(labelWithString: "Waiting for battery status...")
    private let creatorButton = NSButton(title: "Created by Leon.T - GitHub: LeonTOfficial", target: nil, action: nil)

    var onOpenGitHub: (() -> Void)?

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
        subtitleLabel.stringValue = "\(appearance.subtitle) Threshold: \(settings.thresholdPercentage)%"
    }

    private func setup() {
        frame = NSRect(x: 0, y: 0, width: 310, height: 112)

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 8
        root.edgeInsets = NSEdgeInsets(top: 12, left: 14, bottom: 10, right: 14)
        root.translatesAutoresizingMaskIntoConstraints = false

        let topRow = NSStackView()
        topRow.orientation = .horizontal
        topRow.alignment = .centerY
        topRow.spacing = 10

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 30).isActive = true

        let labels = NSStackView()
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 2

        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        subtitleLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.lineBreakMode = .byTruncatingTail

        labels.addArrangedSubview(titleLabel)
        labels.addArrangedSubview(subtitleLabel)
        topRow.addArrangedSubview(iconView)
        topRow.addArrangedSubview(labels)

        creatorButton.isBordered = false
        creatorButton.alignment = .left
        creatorButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        creatorButton.contentTintColor = .linkColor
        creatorButton.target = self
        creatorButton.action = #selector(openGitHub)

        root.addArrangedSubview(topRow)
        root.addArrangedSubview(creatorButton)
        addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor),
            root.trailingAnchor.constraint(equalTo: trailingAnchor),
            root.topAnchor.constraint(equalTo: topAnchor),
            root.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func openGitHub() {
        onOpenGitHub?()
    }
}
