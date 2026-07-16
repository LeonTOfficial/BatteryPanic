import AppKit

enum OverlayDisplayMode {
    case lowBattery
    case criticalBattery
    case chargeReminder
}

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

    var displayMode: OverlayDisplayMode = .lowBattery {
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
        let baseAlpha: CGFloat
        let pulseAlpha: CGFloat

        switch displayMode {
        case .criticalBattery:
            baseAlpha = isTest ? 0.14 : 0.12
            pulseAlpha = 0.16
        case .chargeReminder:
            baseAlpha = 0.07
            pulseAlpha = 0.07
        case .lowBattery:
            baseAlpha = isTest ? 0.12 : 0.085
            pulseAlpha = 0.11
        }

        accentColor.withAlphaComponent((baseAlpha + (pulseAlpha * pulse)) * effectivePulseIntensity).setFill()
        rect.fill()
    }

    private func drawRedVignette(in rect: NSRect) {
        let pulse = pulseEnabled ? pulseValue : 1
        let maxSteps = displayMode == .chargeReminder ? 24 : 34

        for step in 0..<maxSteps {
            let progress = CGFloat(step) / CGFloat(maxSteps)
            let alpha = (0.50 + (0.22 * pulse)) * pow(1 - progress, 2.0) * effectivePulseIntensity
            let inset = progress * min(rect.width, rect.height) * 0.14
            let strokeRect = rect.insetBy(dx: inset, dy: inset)
            let path = NSBezierPath(roundedRect: strokeRect, xRadius: 26, yRadius: 26)
            path.lineWidth = 2.1
            accentColor.withAlphaComponent(alpha * 0.13).setStroke()
            path.stroke()
        }

        let edgePath = NSBezierPath(roundedRect: rect.insetBy(dx: 8, dy: 8), xRadius: 24, yRadius: 24)
        edgePath.lineWidth = displayMode == .criticalBattery ? 5 : 4
        accentColor.withAlphaComponent((0.18 + (0.14 * pulse)) * effectivePulseIntensity).setStroke()
        edgePath.stroke()
    }

    private func drawWarningCard(in rect: NSRect) {
        let pulse = pulseEnabled ? pulseValue : 1
        let cardWidth = min(
            max(rect.width * 0.30, displayMode == .chargeReminder ? 430 : 470),
            displayMode == .chargeReminder ? 520 : 560
        )
        let cardHeight: CGFloat = 132
        let cardRect = NSRect(
            x: rect.midX - (cardWidth / 2),
            y: rect.midY - (cardHeight / 2),
            width: cardWidth,
            height: cardHeight
        )

        let shadow = NSShadow()
        shadow.shadowBlurRadius = 24 + ((pulse * 20) * effectivePulseIntensity)
        shadow.shadowOffset = .zero
        shadow.shadowColor = accentColor.withAlphaComponent((0.28 + (pulse * 0.20)) * effectivePulseIntensity)

        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 32, yRadius: 32)
        cardBackgroundColor.setFill()
        cardPath.fill()
        NSGraphicsContext.restoreGraphicsState()

        let outline = NSBezierPath(roundedRect: cardRect, xRadius: 32, yRadius: 32)
        outline.lineWidth = 1.8
        accentColor.withAlphaComponent(0.60 + (pulse * 0.26)).setStroke()
        outline.stroke()

        drawWarningIcon(in: cardRect, pulse: pulse)
        drawWarningText(in: cardRect)
    }

    private func drawWarningIcon(in cardRect: NSRect, pulse: CGFloat) {
        let badgeRect = NSRect(x: cardRect.minX + 28, y: cardRect.midY - 34, width: 76, height: 68)
        let badge = NSBezierPath(roundedRect: badgeRect, xRadius: 20, yRadius: 20)
        accentColor.withAlphaComponent(0.12 + (pulse * 0.05)).setFill()
        badge.fill()
        badge.lineWidth = 1.5
        accentColor.withAlphaComponent(0.58).setStroke()
        badge.stroke()

        let innerGlow = NSBezierPath(roundedRect: badgeRect.insetBy(dx: 8, dy: 8), xRadius: 15, yRadius: 15)
        innerGlow.lineWidth = 1.2
        accentColor.withAlphaComponent(0.22).setStroke()
        innerGlow.stroke()

        drawBatteryGlyph(
            in: NSRect(x: badgeRect.minX + 16, y: badgeRect.midY - 12, width: 42, height: 24),
            color: accentColor,
            fillFraction: displayMode == .chargeReminder ? CGFloat(percentage) / 100.0 : 0.24
        )
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

        let innerWidth = max(3, bodyRect.width - 10)
        let fillWidth = min(innerWidth, max(innerWidth * 0.16, innerWidth * fillFraction))
        let fill = NSBezierPath(roundedRect: NSRect(x: bodyRect.minX + 5, y: bodyRect.minY + 5, width: fillWidth, height: max(3, bodyRect.height - 10)), xRadius: 3, yRadius: 3)
        color.withAlphaComponent(0.72).setFill()
        fill.fill()
    }

    private func drawWarningText(in cardRect: NSRect) {
        let eyebrow: String
        let title: String
        let subtitle: String

        switch displayMode {
        case .chargeReminder:
            eyebrow = "CHARGING REMINDER"
            title = "Battery reached \(percentage)%"
            subtitle = "You can unplug now, or keep charging if you need more power."
        case .criticalBattery:
            eyebrow = isTest ? "PREVIEW MODE" : "CRITICAL BATTERY"
            title = "\(percentage)% battery left"
            subtitle = timeRemainingText ?? "Plug in now. Your Mac may shut down soon."
        case .lowBattery:
            eyebrow = isTest ? "PREVIEW MODE" : "LOW BATTERY WARNING"
            title = "\(percentage)% battery left"
            subtitle = isTest
                ? "This preview stops automatically after a few seconds."
                : (timeRemainingText ?? "Connect your charger to dismiss this alert.")
        }

        let iconRightEdge = cardRect.minX + 28 + 76
        let textOriginX = iconRightEdge + 28
        let textRightInset: CGFloat = 34
        let textWidth = max(180, cardRect.maxX - textOriginX - textRightInset)
        let titleFontSize: CGFloat = displayMode == .chargeReminder ? 23 : 27

        drawText(
            eyebrow,
            at: NSPoint(x: textOriginX, y: cardRect.minY + 25),
            font: .systemFont(ofSize: 11, weight: .black),
            color: accentColor.withAlphaComponent(0.78),
            kern: 1.0
        )
        drawText(
            title,
            in: NSRect(x: textOriginX, y: cardRect.minY + 43, width: textWidth, height: 36),
            font: .systemFont(ofSize: titleFontSize, weight: .black),
            color: accentColor,
            lineBreakMode: .byTruncatingTail
        )
        drawText(
            subtitle,
            in: NSRect(x: textOriginX + 2, y: cardRect.minY + 84, width: textWidth, height: 34),
            font: .systemFont(ofSize: 14, weight: .medium),
            color: NSColor.white.withAlphaComponent(0.68),
            lineBreakMode: .byWordWrapping
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

    private func drawText(
        _ text: String,
        in rect: NSRect,
        font: NSFont,
        color: NSColor,
        lineBreakMode: NSLineBreakMode
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = lineBreakMode
        paragraph.maximumLineHeight = font.pointSize + 4
        paragraph.minimumLineHeight = font.pointSize + 2

        NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        ).draw(with: rect)
    }

    private var accentColor: NSColor {
        switch displayMode {
        case .chargeReminder:
            return .systemTeal
        case .criticalBattery, .lowBattery:
            return .systemRed
        }
    }

    private var cardBackgroundColor: NSColor {
        switch displayMode {
        case .chargeReminder:
            return NSColor(calibratedRed: 0.04, green: 0.12, blue: 0.12, alpha: 0.95)
        case .criticalBattery, .lowBattery:
            return NSColor(calibratedWhite: 0.075, alpha: 0.95)
        }
    }

    private var effectivePulseIntensity: CGFloat {
        switch displayMode {
        case .criticalBattery:
            return min(pulseIntensity * 1.25, 1.9)
        case .chargeReminder:
            return min(pulseIntensity * 0.72, 1.0)
        case .lowBattery:
            return pulseIntensity
        }
    }
}
