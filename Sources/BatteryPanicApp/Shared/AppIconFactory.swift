import AppKit

enum AppIconFactory {
    static func image(size: CGFloat = 56) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let bounds = NSRect(x: 0, y: 0, width: size, height: size)
        let radius = size * 0.22
        let background = NSBezierPath(
            roundedRect: bounds.insetBy(dx: size * 0.06, dy: size * 0.06),
            xRadius: radius,
            yRadius: radius
        )
        NSColor(calibratedWhite: 0.085, alpha: 1).setFill()
        background.fill()

        let glow = NSBezierPath(
            roundedRect: bounds.insetBy(dx: size * 0.10, dy: size * 0.10),
            xRadius: radius * 0.82,
            yRadius: radius * 0.82
        )
        glow.lineWidth = max(1.5, size * 0.028)
        NSColor.systemRed.withAlphaComponent(0.62).setStroke()
        glow.stroke()

        let bodyRect = NSRect(
            x: size * 0.22,
            y: size * 0.38,
            width: size * 0.49,
            height: size * 0.24
        )
        let body = NSBezierPath(
            roundedRect: bodyRect,
            xRadius: size * 0.052,
            yRadius: size * 0.052
        )
        body.lineWidth = max(1.8, size * 0.034)
        NSColor.systemRed.setStroke()
        body.stroke()

        let nub = NSBezierPath(
            roundedRect: NSRect(
                x: bodyRect.maxX + size * 0.036,
                y: bodyRect.midY - size * 0.052,
                width: size * 0.055,
                height: size * 0.104
            ),
            xRadius: size * 0.02,
            yRadius: size * 0.02
        )
        NSColor.systemRed.setFill()
        nub.fill()

        let lowFill = NSBezierPath(
            roundedRect: NSRect(
                x: bodyRect.minX + size * 0.055,
                y: bodyRect.minY + size * 0.055,
                width: size * 0.11,
                height: bodyRect.height - size * 0.11
            ),
            xRadius: size * 0.02,
            yRadius: size * 0.02
        )
        NSColor.systemRed.withAlphaComponent(0.78).setFill()
        lowFill.fill()

        let pulseLine = NSBezierPath(
            roundedRect: NSRect(x: size * 0.28, y: size * 0.26, width: size * 0.40, height: size * 0.035),
            xRadius: size * 0.017,
            yRadius: size * 0.017
        )
        NSColor.systemRed.withAlphaComponent(0.34).setFill()
        pulseLine.fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
