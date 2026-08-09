import AppKit

final class OnboardingHeroView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 24
        layer?.masksToBounds = false
        setAccessibilityElement(true)
        setAccessibilityRole(.image)
        setAccessibilityLabel("Battery Panic menu bar and low battery alert preview")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawPanel(in: bounds)
        drawMenuPreview(in: bounds)
        drawPulsePreview(in: bounds)
        drawAlertPreview(in: bounds)
    }

    private func drawPanel(in rect: NSRect) {
        let panel = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 24, yRadius: 24)
        NSColor(calibratedRed: 0.055, green: 0.057, blue: 0.065, alpha: 1).setFill()
        panel.fill()

        let topWash = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 24, yRadius: 24)
        NSColor.systemRed.withAlphaComponent(0.10).setFill()
        topWash.fill()

        NSColor.white.withAlphaComponent(0.09).setStroke()
        panel.lineWidth = 1
        panel.stroke()
    }

    private func drawMenuPreview(in rect: NSRect) {
        let menuRect = NSRect(x: rect.minX + 22, y: rect.minY + 22, width: rect.width - 44, height: 48)
        NSColor(calibratedWhite: 0.13, alpha: 0.90).setFill()
        NSBezierPath(roundedRect: menuRect, xRadius: 16, yRadius: 16).fill()

        drawBatteryGlyph(
            in: NSRect(x: menuRect.minX + 18, y: menuRect.midY - 9, width: 34, height: 18),
            color: .systemRed,
            fillFraction: 0.22
        )
        drawText("9%", at: NSPoint(x: menuRect.minX + 66, y: menuRect.minY + 15), font: .monospacedDigitSystemFont(ofSize: 17, weight: .semibold), color: .white)
        drawText("Battery Panic", at: NSPoint(x: menuRect.maxX - 124, y: menuRect.minY + 16), font: .systemFont(ofSize: 13, weight: .medium), color: NSColor.white.withAlphaComponent(0.58))
    }

    private func drawPulsePreview(in rect: NSRect) {
        let pulseRect = rect.insetBy(dx: 22, dy: 92)
        for step in 0..<18 {
            let progress = CGFloat(step) / 18.0
            let insetX = progress * 42
            let insetY = progress * 28
            let path = NSBezierPath(roundedRect: pulseRect.insetBy(dx: insetX, dy: insetY), xRadius: 20, yRadius: 20)
            path.lineWidth = 2
            NSColor.systemRed.withAlphaComponent((1 - progress) * 0.075).setStroke()
            path.stroke()
        }
    }

    private func drawAlertPreview(in rect: NSRect) {
        let cardRect = NSRect(x: rect.midX - 132, y: rect.midY - 44, width: 264, height: 112)
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 28
        shadow.shadowOffset = .zero
        shadow.shadowColor = NSColor.systemRed.withAlphaComponent(0.34)

        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        NSColor(calibratedWhite: 0.08, alpha: 0.96).setFill()
        NSBezierPath(roundedRect: cardRect, xRadius: 28, yRadius: 28).fill()
        NSGraphicsContext.restoreGraphicsState()

        let outline = NSBezierPath(roundedRect: cardRect, xRadius: 28, yRadius: 28)
        outline.lineWidth = 1.6
        NSColor.systemRed.withAlphaComponent(0.72).setStroke()
        outline.stroke()

        let iconRect = NSRect(x: cardRect.minX + 24, y: cardRect.midY - 20, width: 58, height: 40)
        drawAlertBadge(in: iconRect)
        drawText("LOW BATTERY", at: NSPoint(x: cardRect.minX + 98, y: cardRect.minY + 28), font: .systemFont(ofSize: 11, weight: .black), color: NSColor.systemRed.withAlphaComponent(0.74))
        drawText("9% left", at: NSPoint(x: cardRect.minX + 98, y: cardRect.minY + 48), font: .systemFont(ofSize: 26, weight: .black), color: .systemRed)
        drawText("Connect power", at: NSPoint(x: cardRect.minX + 100, y: cardRect.minY + 82), font: .systemFont(ofSize: 13, weight: .medium), color: NSColor.white.withAlphaComponent(0.62))
    }

    private func drawAlertBadge(in rect: NSRect) {
        NSColor.systemRed.withAlphaComponent(0.13).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 14, yRadius: 14).fill()
        NSColor.systemRed.withAlphaComponent(0.68).setStroke()
        let badge = NSBezierPath(roundedRect: rect, xRadius: 14, yRadius: 14)
        badge.lineWidth = 1.4
        badge.stroke()

        drawBatteryGlyph(in: rect.insetBy(dx: 10, dy: 11), color: .systemRed, fillFraction: 0.24)
    }

    private func drawBatteryGlyph(in rect: NSRect, color: NSColor, fillFraction: CGFloat) {
        let bodyRect = NSRect(x: rect.minX, y: rect.midY - rect.height * 0.36, width: rect.width * 0.82, height: rect.height * 0.72)
        let body = NSBezierPath(roundedRect: bodyRect, xRadius: rect.height * 0.18, yRadius: rect.height * 0.18)
        body.lineWidth = max(1.8, rect.height * 0.12)
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

    private func drawText(_ text: String, at point: NSPoint, font: NSFont, color: NSColor) {
        NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color
            ]
        ).draw(at: point)
    }
}
