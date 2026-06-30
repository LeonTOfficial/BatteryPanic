import AppKit

final class OverlayView: NSView {
    var percentage: Int = 10 {
        didSet { needsDisplay = true }
    }

    var timeRemainingText: String? {
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
        drawWarningCard(in: bounds)
    }

    private func drawRedWash(in rect: NSRect) {
        let pulse = pulseEnabled ? pulseValue : 1
        let baseAlpha: CGFloat = isTest ? 0.12 : 0.085
        NSColor.systemRed.withAlphaComponent((baseAlpha + (0.11 * pulse)) * pulseIntensity).setFill()
        rect.fill()
    }

    private func drawRedVignette(in rect: NSRect) {
        let pulse = pulseEnabled ? pulseValue : 1
        let maxSteps = 34

        for step in 0..<maxSteps {
            let progress = CGFloat(step) / CGFloat(maxSteps)
            let alpha = (0.55 + (0.22 * pulse)) * pow(1 - progress, 2.0) * pulseIntensity
            let inset = progress * min(rect.width, rect.height) * 0.14
            let strokeRect = rect.insetBy(dx: inset, dy: inset)
            let path = NSBezierPath(roundedRect: strokeRect, xRadius: 26, yRadius: 26)
            path.lineWidth = 2.1
            NSColor.systemRed.withAlphaComponent(alpha * 0.13).setStroke()
            path.stroke()
        }

        let edgePath = NSBezierPath(roundedRect: rect.insetBy(dx: 8, dy: 8), xRadius: 24, yRadius: 24)
        edgePath.lineWidth = 4
        NSColor.systemRed.withAlphaComponent((0.20 + (0.14 * pulse)) * pulseIntensity).setStroke()
        edgePath.stroke()
    }

    private func drawWarningCard(in rect: NSRect) {
        let pulse = pulseEnabled ? pulseValue : 1
        let cardWidth = min(max(rect.width * 0.38, 500), 640)
        let cardHeight: CGFloat = 132
        let cardRect = NSRect(
            x: rect.midX - (cardWidth / 2),
            y: rect.midY - (cardHeight / 2),
            width: cardWidth,
            height: cardHeight
        )

        let shadow = NSShadow()
        shadow.shadowBlurRadius = 26 + ((pulse * 18) * pulseIntensity)
        shadow.shadowOffset = .zero
        shadow.shadowColor = NSColor.systemRed.withAlphaComponent((0.30 + (pulse * 0.18)) * pulseIntensity)

        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 32, yRadius: 32)
        NSColor(calibratedWhite: 0.075, alpha: 0.95).setFill()
        cardPath.fill()
        NSGraphicsContext.restoreGraphicsState()

        let outline = NSBezierPath(roundedRect: cardRect, xRadius: 32, yRadius: 32)
        outline.lineWidth = 1.8
        NSColor.systemRed.withAlphaComponent(0.64 + (pulse * 0.24)).setStroke()
        outline.stroke()

        drawWarningIcon(in: cardRect, pulse: pulse)
        drawWarningText(in: cardRect)
    }

    private func drawWarningIcon(in cardRect: NSRect, pulse: CGFloat) {
        let badgeRect = NSRect(x: cardRect.minX + 28, y: cardRect.midY - 34, width: 76, height: 68)
        let badge = NSBezierPath(roundedRect: badgeRect, xRadius: 20, yRadius: 20)
        NSColor.systemRed.withAlphaComponent(0.12 + (pulse * 0.04)).setFill()
        badge.fill()
        badge.lineWidth = 1.5
        NSColor.systemRed.withAlphaComponent(0.58).setStroke()
        badge.stroke()

        let innerGlow = NSBezierPath(roundedRect: badgeRect.insetBy(dx: 8, dy: 8), xRadius: 15, yRadius: 15)
        innerGlow.lineWidth = 1.2
        NSColor.systemRed.withAlphaComponent(0.22).setStroke()
        innerGlow.stroke()

        drawBatteryGlyph(in: NSRect(x: badgeRect.minX + 16, y: badgeRect.midY - 12, width: 42, height: 24), color: .systemRed, fillFraction: 0.24)
    }

    private func drawBatteryGlyph(in rect: NSRect, color: NSColor, fillFraction: CGFloat) {
        let bodyRect = NSRect(x: rect.minX, y: rect.midY - rect.height * 0.36, width: rect.width * 0.82, height: rect.height * 0.72)
        let body = NSBezierPath(roundedRect: bodyRect, xRadius: rect.height * 0.18, yRadius: rect.height * 0.18)
        body.lineWidth = max(2.0, rect.height * 0.12)
        color.setStroke()
        body.stroke()

        let nub = NSBezierPath(roundedRect: NSRect(x: bodyRect.maxX + rect.width * 0.07, y: bodyRect.midY - bodyRect.height * 0.22, width: rect.width * 0.09, height: bodyRect.height * 0.44), xRadius: 2, yRadius: 2)
        color.setFill()
        nub.fill()

        let fillWidth = max(bodyRect.width * 0.16, bodyRect.width * fillFraction)
        let fill = NSBezierPath(roundedRect: NSRect(x: bodyRect.minX + 5, y: bodyRect.minY + 5, width: fillWidth, height: max(3, bodyRect.height - 10)), xRadius: 3, yRadius: 3)
        color.withAlphaComponent(0.72).setFill()
        fill.fill()
    }

    private func drawWarningText(in cardRect: NSRect) {
        let eyebrow = isTest ? "PREVIEW MODE" : "LOW BATTERY WARNING"
        let title = "\(percentage)% battery left"
        let subtitle = isTest
            ? "This preview stops automatically after a few seconds."
            : (timeRemainingText ?? "Connect your charger to dismiss this alert.")
        let textOriginX = cardRect.minX + 124

        drawText(
            eyebrow,
            at: NSPoint(x: textOriginX, y: cardRect.minY + 25),
            font: .systemFont(ofSize: 11, weight: .black),
            color: NSColor.systemRed.withAlphaComponent(0.72),
            kern: 1.0
        )
        drawText(
            title,
            at: NSPoint(x: textOriginX, y: cardRect.minY + 47),
            font: .systemFont(ofSize: 31, weight: .black),
            color: .systemRed
        )
        drawText(
            subtitle,
            at: NSPoint(x: textOriginX + 2, y: cardRect.minY + 88),
            font: .systemFont(ofSize: 14, weight: .medium),
            color: NSColor.white.withAlphaComponent(0.68)
        )
    }

    private func drawText(_ text: String, at point: NSPoint, font: NSFont, color: NSColor, kern: CGFloat = 0) {
        NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .kern: kern
            ]
        ).draw(at: point)
    }
}
