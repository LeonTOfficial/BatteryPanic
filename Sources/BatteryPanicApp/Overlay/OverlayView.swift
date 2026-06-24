import AppKit

final class OverlayView: NSView {
    var percentage: Int = 10 {
        didSet { needsDisplay = true }
    }

    var isTest: Bool = false {
        didSet { needsDisplay = true }
    }

    var pulseEnabled: Bool = true {
        didSet { needsDisplay = true }
    }

    var pulseValue: CGFloat = 0 {
        didSet { needsDisplay = true }
    }

    var pulseIntensity: CGFloat = 1 {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawRedWash(in: bounds)
        drawRedVignette(in: bounds)
        drawWarningPill(in: bounds)
    }

    private func drawRedWash(in rect: NSRect) {
        let pulse = pulseEnabled ? pulseValue : 1
        let baseAlpha: CGFloat = isTest ? 0.13 : 0.09
        NSColor.systemRed.withAlphaComponent((baseAlpha + (0.12 * pulse)) * pulseIntensity).setFill()
        rect.fill()
    }

    private func drawRedVignette(in rect: NSRect) {
        let pulse = pulseEnabled ? pulseValue : 1
        let maxSteps = 92

        for step in 0..<maxSteps {
            let progress = CGFloat(step) / CGFloat(maxSteps)
            let alpha = (0.55 + (0.24 * pulse)) * pow(1 - progress, 2.0) * pulseIntensity
            let inset = progress * min(rect.width, rect.height) * 0.14
            let strokeRect = rect.insetBy(dx: inset, dy: inset)
            let path = NSBezierPath(roundedRect: strokeRect, xRadius: 26, yRadius: 26)
            path.lineWidth = 3
            NSColor.systemRed.withAlphaComponent(alpha * 0.14).setStroke()
            path.stroke()
        }

        let edgePath = NSBezierPath(roundedRect: rect.insetBy(dx: 8, dy: 8), xRadius: 24, yRadius: 24)
        edgePath.lineWidth = 4
        NSColor.systemRed.withAlphaComponent((0.23 + (0.16 * pulse)) * pulseIntensity).setStroke()
        edgePath.stroke()
    }

    private func drawWarningPill(in rect: NSRect) {
        let pulse = pulseEnabled ? pulseValue : 1
        let pillWidth = min(max(rect.width * 0.38, 420), 560)
        let pillHeight: CGFloat = 92
        let pillRect = NSRect(
            x: rect.midX - (pillWidth / 2),
            y: rect.midY - (pillHeight / 2),
            width: pillWidth,
            height: pillHeight
        )

        let shadow = NSShadow()
        shadow.shadowBlurRadius = 24 + ((pulse * 16) * pulseIntensity)
        shadow.shadowOffset = .zero
        shadow.shadowColor = NSColor.systemRed.withAlphaComponent((0.34 + (pulse * 0.20)) * pulseIntensity)

        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: 36, yRadius: 36)
        NSColor(calibratedWhite: 0.11, alpha: 0.92).setFill()
        pillPath.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSColor.systemRed.withAlphaComponent(0.70 + (pulse * 0.25)).setStroke()
        pillPath.lineWidth = 2
        pillPath.stroke()

        drawBatteryIcon(in: pillRect)
        drawPillText(in: pillRect)
    }

    private func drawBatteryIcon(in pillRect: NSRect) {
        let iconRect = NSRect(x: pillRect.minX + 36, y: pillRect.midY - 12, width: 40, height: 24)
        let body = NSBezierPath(roundedRect: iconRect, xRadius: 6, yRadius: 6)
        body.lineWidth = 3
        NSColor.systemRed.setStroke()
        body.stroke()

        let nubRect = NSRect(x: iconRect.maxX + 4, y: iconRect.midY - 5, width: 5, height: 10)
        let nub = NSBezierPath(roundedRect: nubRect, xRadius: 2, yRadius: 2)
        NSColor.systemRed.setFill()
        nub.fill()

        let chargeRect = NSRect(x: iconRect.minX + 6, y: iconRect.minY + 6, width: 10, height: 12)
        let charge = NSBezierPath(roundedRect: chargeRect, xRadius: 3, yRadius: 3)
        NSColor.systemRed.withAlphaComponent(0.55).setFill()
        charge.fill()
    }

    private func drawPillText(in pillRect: NSRect) {
        let title = isTest ? "Preview: \(percentage)% Remaining" : "\(percentage)% Remaining"
        let subtitle = isTest ? "This is how Battery Panic looks below your threshold" : "Connect charger immediately"
        let textOriginX = pillRect.minX + 102

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: NSColor.systemRed
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: NSColor.systemRed.withAlphaComponent(0.78)
        ]

        NSAttributedString(string: title, attributes: titleAttributes).draw(
            at: NSPoint(x: textOriginX, y: pillRect.minY + 25)
        )
        NSAttributedString(string: subtitle, attributes: subtitleAttributes).draw(
            at: NSPoint(x: textOriginX, y: pillRect.minY + 52)
        )
    }
}
