import AppKit

final class OverlayPreviewView: NSView {
    private var timer: Timer?
    private var animationStart = Date()

    var pulseEnabled = true {
        didSet { needsDisplay = true }
    }

    var pulseSpeed: Double = 1.0 {
        didSet { needsDisplay = true }
    }

    var pulseIntensity: Double = 1.0 {
        didSet { needsDisplay = true }
    }

    private var pulseValue: CGFloat = 0 {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 12
        startAnimation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    func configure(pulseEnabled: Bool, pulseSpeed: Double, pulseIntensity: Double) {
        self.pulseEnabled = pulseEnabled
        self.pulseSpeed = pulseSpeed
        self.pulseIntensity = pulseIntensity
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let rect = bounds.insetBy(dx: 0, dy: 0)
        let pulse = pulseEnabled ? pulseValue : 1
        let intensity = CGFloat(pulseIntensity)

        NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12).fill()

        NSColor.systemRed.withAlphaComponent((0.08 + pulse * 0.16) * intensity).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12).fill()

        for step in 0..<28 {
            let progress = CGFloat(step) / 28.0
            let inset = 6 + progress * 34
            let alpha = (0.36 + pulse * 0.24) * pow(1 - progress, 1.8) * intensity
            let path = NSBezierPath(roundedRect: rect.insetBy(dx: inset, dy: inset * 0.55), xRadius: 12, yRadius: 12)
            path.lineWidth = 2
            NSColor.systemRed.withAlphaComponent(alpha * 0.18).setStroke()
            path.stroke()
        }

        drawPreviewPill(in: rect, pulse: pulse, intensity: intensity)
    }

    private func drawPreviewPill(in rect: NSRect, pulse: CGFloat, intensity: CGFloat) {
        let pill = NSRect(x: rect.midX - 116, y: rect.midY - 28, width: 232, height: 56)
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 12 + pulse * 12 * intensity
        shadow.shadowColor = NSColor.systemRed.withAlphaComponent(0.36 * intensity)
        shadow.shadowOffset = .zero

        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        NSColor(calibratedWhite: 0.09, alpha: 0.95).setFill()
        NSBezierPath(roundedRect: pill, xRadius: 18, yRadius: 18).fill()
        NSGraphicsContext.restoreGraphicsState()

        let label = NSAttributedString(
            string: "Live overlay preview",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: NSColor.systemRed
            ]
        )
        label.draw(at: NSPoint(x: pill.minX + 22, y: pill.minY + 12))

        let detail = NSAttributedString(
            string: String(format: "%.1fx  ·  %d%%", pulseSpeed, Int(pulseIntensity * 100)),
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.white.withAlphaComponent(0.72)
            ]
        )
        detail.draw(at: NSPoint(x: pill.minX + 22, y: pill.minY + 32))
    }

    private func startAnimation() {
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        let elapsed = Date().timeIntervalSince(animationStart)
        pulseValue = CGFloat((sin(elapsed * 2.4 * pulseSpeed) + 1) / 2)
    }
}
