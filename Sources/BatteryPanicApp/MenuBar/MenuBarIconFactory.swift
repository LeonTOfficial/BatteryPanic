import AppKit

enum MenuBarIconFactory {
    static func image(isLow: Bool, isPaused: Bool) -> NSImage {
        let appearance = BatteryStatusAppearance(
            level: isLow ? .critical : .healthy,
            color: isPaused ? .secondaryLabelColor : (isLow ? .systemRed : .systemGreen),
            title: "",
            subtitle: "",
            showsBolt: false,
            showsCriticalDot: isLow
        )
        return image(appearance: appearance, percentage: isLow ? 9 : 80)
    }

    static func image(appearance: BatteryStatusAppearance, percentage: Int) -> NSImage {
        image(appearance: appearance, percentage: percentage, size: NSSize(width: 22, height: 18))
    }

    static func image(appearance: BatteryStatusAppearance, percentage: Int, size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()

        let color = appearance.color
        let scaleX = size.width / 22
        let scaleY = size.height / 18
        let stroke = max(1.6, min(scaleX, scaleY) * 1.7)

        let bodyRect = NSRect(
            x: 2.4 * scaleX,
            y: 4.4 * scaleY,
            width: 14.8 * scaleX,
            height: 8.8 * scaleY
        )
        let body = NSBezierPath(
            roundedRect: bodyRect,
            xRadius: 2.2 * min(scaleX, scaleY),
            yRadius: 2.2 * min(scaleX, scaleY)
        )
        body.lineWidth = stroke
        color.setStroke()
        body.stroke()

        let nub = NSBezierPath(
            roundedRect: NSRect(x: 18.1 * scaleX, y: 6.6 * scaleY, width: 2.4 * scaleX, height: 4.8 * scaleY),
            xRadius: 1.2 * min(scaleX, scaleY),
            yRadius: 1.2 * min(scaleX, scaleY)
        )
        color.setFill()
        nub.fill()

        let maxFillWidth = 10.9 * scaleX
        let fillWidth = max(2.2 * scaleX, min(maxFillWidth, CGFloat(percentage) / 100.0 * maxFillWidth))
        let fill = NSBezierPath(
            roundedRect: NSRect(x: 4.8 * scaleX, y: 6.7 * scaleY, width: fillWidth, height: 4.2 * scaleY),
            xRadius: 1.1 * min(scaleX, scaleY),
            yRadius: 1.1 * min(scaleX, scaleY)
        )
        color.withAlphaComponent(0.76).setFill()
        fill.fill()

        if appearance.showsCriticalDot {
            let alertDot = NSBezierPath(
                ovalIn: NSRect(x: 15.7 * scaleX, y: 2.1 * scaleY, width: 3.5 * scaleX, height: 3.5 * scaleY)
            )
            NSColor.systemRed.withAlphaComponent(0.9).setFill()
            alertDot.fill()
        }

        if appearance.showsBolt {
            drawText(
                "⚡",
                in: NSRect(x: 6.1 * scaleX, y: 0.8 * scaleY, width: 10 * scaleX, height: 11 * scaleY),
                color: color,
                size: 9 * min(scaleX, scaleY),
                weight: .bold
            )
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private static func drawText(
        _ text: String,
        in rect: NSRect,
        color: NSColor,
        size: CGFloat,
        weight: NSFont.Weight
    ) {
        let value = NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.systemFont(ofSize: size, weight: weight),
                .foregroundColor: color
            ]
        )
        value.draw(in: rect)
    }
}
