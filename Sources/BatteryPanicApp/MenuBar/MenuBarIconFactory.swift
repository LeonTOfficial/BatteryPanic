import AppKit

enum MenuBarIconFactory {
    static func image(isLow: Bool, isPaused: Bool) -> NSImage {
        let appearance = BatteryStatusAppearance(
            level: isLow ? .critical : .healthy,
            color: isPaused ? .secondaryLabelColor : (isLow ? .systemRed : .systemGreen),
            title: "",
            subtitle: "",
            showsBolt: false,
            showsExclamation: isLow
        )
        return image(appearance: appearance, percentage: isLow ? 9 : 80)
    }

    static func image(appearance: BatteryStatusAppearance, percentage: Int) -> NSImage {
        let size = NSSize(width: 19, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        let color = appearance.color

        let bodyRect = NSRect(x: 2, y: 4, width: 13, height: 9)
        let body = NSBezierPath(roundedRect: bodyRect, xRadius: 2.2, yRadius: 2.2)
        body.lineWidth = 1.7
        color.setStroke()
        body.stroke()

        let nub = NSBezierPath(roundedRect: NSRect(x: 16, y: 6.2, width: 2, height: 4.6), xRadius: 1, yRadius: 1)
        color.setFill()
        nub.fill()

        let fillWidth = max(2.4, min(10.2, CGFloat(percentage) / 100.0 * 10.2))
        let fill = NSBezierPath(roundedRect: NSRect(x: 4.1, y: 6.1, width: fillWidth, height: 4.8), xRadius: 1, yRadius: 1)
        color.withAlphaComponent(0.76).setFill()
        fill.fill()

        if appearance.showsExclamation {
            NSColor.systemRed.withAlphaComponent(0.18).setFill()
            NSBezierPath(ovalIn: NSRect(x: 0, y: 1, width: 18, height: 16)).fill()
            drawText("!", in: NSRect(x: 7.2, y: 1.3, width: 6, height: 8), color: .systemRed, size: 8, weight: .black)
        }

        if appearance.showsBolt {
            drawText("⌁", in: NSRect(x: 6.2, y: 1.0, width: 9, height: 11), color: color, size: 10, weight: .bold)
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
