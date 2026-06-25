import AppKit

enum AppIconFactory {
    static func image(size: CGFloat = 56) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let bounds = NSRect(x: 0, y: 0, width: size, height: size)
        let background = NSBezierPath(
            roundedRect: bounds.insetBy(dx: size * 0.055, dy: size * 0.055),
            xRadius: size * 0.22,
            yRadius: size * 0.22
        )
        NSColor(calibratedRed: 0.055, green: 0.057, blue: 0.065, alpha: 1).setFill()
        background.fill()

        let ring = NSBezierPath(
            roundedRect: bounds.insetBy(dx: size * 0.11, dy: size * 0.11),
            xRadius: size * 0.18,
            yRadius: size * 0.18
        )
        ring.lineWidth = max(1.8, size * 0.026)
        NSColor.systemRed.withAlphaComponent(0.62).setStroke()
        ring.stroke()

        let softRing = NSBezierPath(
            roundedRect: bounds.insetBy(dx: size * 0.18, dy: size * 0.18),
            xRadius: size * 0.13,
            yRadius: size * 0.13
        )
        softRing.lineWidth = max(1.0, size * 0.012)
        NSColor.systemRed.withAlphaComponent(0.20).setStroke()
        softRing.stroke()

        let batteryRect = NSRect(x: size * 0.23, y: size * 0.39, width: size * 0.48, height: size * 0.23)
        drawBattery(in: batteryRect, color: .systemRed, size: size)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private static func drawBattery(in rect: NSRect, color: NSColor, size: CGFloat) {
        let body = NSBezierPath(roundedRect: rect, xRadius: size * 0.052, yRadius: size * 0.052)
        body.lineWidth = max(2, size * 0.034)
        color.setStroke()
        body.stroke()

        let nub = NSBezierPath(
            roundedRect: NSRect(x: rect.maxX + size * 0.035, y: rect.midY - size * 0.05, width: size * 0.052, height: size * 0.10),
            xRadius: size * 0.018,
            yRadius: size * 0.018
        )
        color.setFill()
        nub.fill()

        let lowFill = NSBezierPath(
            roundedRect: NSRect(x: rect.minX + size * 0.055, y: rect.minY + size * 0.055, width: size * 0.12, height: rect.height - size * 0.11),
            xRadius: size * 0.018,
            yRadius: size * 0.018
        )
        color.withAlphaComponent(0.76).setFill()
        lowFill.fill()
    }
}
