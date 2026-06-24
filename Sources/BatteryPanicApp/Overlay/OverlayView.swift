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
        let maxSteps = 38

        for step in 0..<maxSteps {
            let progress = CGFloat(step) / CGFloat(maxSteps)
            let alpha = (0.55 + (0.24 * pulse)) * pow(1 - progress, 2.0) * pulseIntensity
            let inset = progress * min(rect.width, rect.height) * 0.14
            let strokeRect = rect.insetBy(dx: inset, dy: inset)
            let path = NSBezierPath(roundedRect: strokeRect, xRadius: 26, yRadius: 26)
            path.lineWidth = 2.2
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
        let pillWidth = min(max(rect.width * 0.34, 420), 520)
        let pillHeight: CGFloat = 118
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
        let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: 28, yRadius: 28)
        NSColor(calibratedWhite: 0.08, alpha: 0.94).setFill()
        pillPath.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSColor.systemRed.withAlphaComponent(0.70 + (pulse * 0.25)).setStroke()
        pillPath.lineWidth = 2
        pillPath.stroke()

        drawPanicBadge(in: pillRect)
        drawPillText(in: pillRect)
    }

    private func drawPanicBadge(in pillRect: NSRect) {
        let badgeRect = NSRect(x: pillRect.minX + 30, y: pillRect.midY - 28, width: 58, height: 56)
        let badge = NSBezierPath(roundedRect: badgeRect, xRadius: 16, yRadius: 16)
        NSColor.systemRed.withAlphaComponent(0.14).setFill()
        badge.fill()
        NSColor.systemRed.withAlphaComponent(0.82).setStroke()
        badge.lineWidth = 2
        badge.stroke()

        let iconRect = NSRect(x: badgeRect.midX - 20, y: badgeRect.midY - 9, width: 34, height: 18)
        let body = NSBezierPath(roundedRect: iconRect, xRadius: 6, yRadius: 6)
        body.lineWidth = 2.4
        NSColor.systemRed.setStroke()
        body.stroke()

        let nubRect = NSRect(x: iconRect.maxX + 3, y: iconRect.midY - 4, width: 4, height: 8)
        let nub = NSBezierPath(roundedRect: nubRect, xRadius: 2, yRadius: 2)
        NSColor.systemRed.setFill()
        nub.fill()

        let chargeRect = NSRect(x: iconRect.minX + 5, y: iconRect.minY + 5, width: 8, height: 8)
        let charge = NSBezierPath(roundedRect: chargeRect, xRadius: 3, yRadius: 3)
        NSColor.systemRed.withAlphaComponent(0.55).setFill()
        charge.fill()

        let accentRects = [
            NSRect(x: badgeRect.maxX - 12, y: badgeRect.minY + 13, width: 4, height: 4),
            NSRect(x: badgeRect.maxX - 12, y: badgeRect.minY + 24, width: 4, height: 4),
            NSRect(x: badgeRect.maxX - 12, y: badgeRect.minY + 35, width: 4, height: 4)
        ]
        accentRects.forEach { rect in
            let dot = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
            NSColor.systemRed.withAlphaComponent(0.82).setFill()
            dot.fill()
        }
    }

    private func drawPillText(in pillRect: NSRect) {
        let eyebrow = isTest ? "BATTERY PANIC PREVIEW" : "BATTERY PANIC"
        let title = "Low power: \(percentage)%"
        let subtitle = isTest ? "Live warning preview using your settings" : "Plug in your charger to dismiss this alert"
        let textOriginX = pillRect.minX + 112

        let eyebrowAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .black),
            .foregroundColor: NSColor.systemRed.withAlphaComponent(0.75),
            .kern: 1.1
        ]
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 26, weight: .black),
            .foregroundColor: NSColor.systemRed
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.72)
        ]

        NSAttributedString(string: eyebrow, attributes: eyebrowAttributes).draw(
            at: NSPoint(x: textOriginX, y: pillRect.minY + 24)
        )
        NSAttributedString(string: title, attributes: titleAttributes).draw(
            at: NSPoint(x: textOriginX, y: pillRect.minY + 43)
        )
        NSAttributedString(string: subtitle, attributes: subtitleAttributes).draw(
            at: NSPoint(x: textOriginX, y: pillRect.minY + 78)
        )
    }

}
