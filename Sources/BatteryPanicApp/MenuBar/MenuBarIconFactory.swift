import AppKit

struct BatteryIconGeometry {
    static let canvasSize = NSSize(width: 22, height: 18)

    let scale: CGFloat
    let origin: NSPoint
    let bodyRect: NSRect
    let capRect: NSRect
    let innerRect: NSRect

    init(size: NSSize) {
        let computedScale = min(
            size.width / Self.canvasSize.width,
            size.height / Self.canvasSize.height
        )
        let renderedSize = NSSize(
            width: Self.canvasSize.width * computedScale,
            height: Self.canvasSize.height * computedScale
        )
        let computedOrigin = NSPoint(
            x: (size.width - renderedSize.width) / 2,
            y: (size.height - renderedSize.height) / 2
        )
        func scaledRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
            NSRect(
                x: computedOrigin.x + x * computedScale,
                y: computedOrigin.y + y * computedScale,
                width: width * computedScale,
                height: height * computedScale
            )
        }
        scale = computedScale
        origin = computedOrigin
        bodyRect = scaledRect(x: 2.0, y: 4.2, width: 15.2, height: 9.6)
        capRect = scaledRect(x: 18.1, y: 6.8, width: 2.1, height: 4.4)
        innerRect = scaledRect(x: 4.1, y: 6.2, width: 11.0, height: 5.6)
    }

    func fillRect(percentage: Int) -> NSRect {
        let fraction = CGFloat(percentage.clamped(to: 0...100)) / 100
        return NSRect(
            x: innerRect.minX,
            y: innerRect.minY,
            width: innerRect.width * fraction,
            height: innerRect.height
        )
    }

    func point(x: CGFloat, y: CGFloat) -> NSPoint {
        NSPoint(x: origin.x + x * scale, y: origin.y + y * scale)
    }

    func rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
        NSRect(
            x: origin.x + x * scale,
            y: origin.y + y * scale,
            width: width * scale,
            height: height * scale
        )
    }
}

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
        image(
            appearance: appearance,
            percentage: percentage,
            size: NSSize(width: 22, height: 18),
            showsChargingIndicator: true
        )
    }

    static func image(
        appearance: BatteryStatusAppearance,
        percentage: Int,
        size: NSSize,
        showsChargingIndicator: Bool = true
    ) -> NSImage {
        let image = NSImage(size: size, flipped: false) { destinationRect in
            draw(
                appearance: appearance,
                percentage: percentage,
                showsChargingIndicator: showsChargingIndicator,
                in: destinationRect.size
            )
            return true
        }
        image.isTemplate = false
        return image
    }

    private static func draw(
        appearance: BatteryStatusAppearance,
        percentage: Int,
        showsChargingIndicator: Bool,
        in size: NSSize
    ) {
        let geometry = BatteryIconGeometry(size: size)
        let color = appearance.color
        let strokeWidth = max(1.35, 1.55 * geometry.scale)

        NSGraphicsContext.current?.cgContext.setShouldAntialias(true)
        NSGraphicsContext.current?.cgContext.setAllowsAntialiasing(true)

        let body = NSBezierPath(
            roundedRect: geometry.bodyRect,
            xRadius: 2.2 * geometry.scale,
            yRadius: 2.2 * geometry.scale
        )
        body.lineWidth = strokeWidth
        color.setStroke()
        body.stroke()

        let cap = NSBezierPath(
            roundedRect: geometry.capRect,
            xRadius: 1.0 * geometry.scale,
            yRadius: 1.0 * geometry.scale
        )
        color.setFill()
        cap.fill()

        let fillRect = geometry.fillRect(percentage: percentage)
        if fillRect.width > 0 {
            NSGraphicsContext.saveGraphicsState()
            let fillClip = NSBezierPath(
                roundedRect: geometry.innerRect,
                xRadius: 1.45 * geometry.scale,
                yRadius: 1.45 * geometry.scale
            )
            fillClip.addClip()
            color.withAlphaComponent(0.88).setFill()
            NSBezierPath(rect: fillRect).fill()
            NSGraphicsContext.restoreGraphicsState()
        }

        if appearance.showsBolt && showsChargingIndicator {
            drawChargingBolt(geometry: geometry)
        }

        if appearance.showsCriticalDot {
            drawCriticalBadge(geometry: geometry)
        }
    }

    private static func drawChargingBolt(geometry: BatteryIconGeometry) {
        let bolt = NSBezierPath()
        bolt.move(to: geometry.point(x: 10.9, y: 12.4))
        bolt.line(to: geometry.point(x: 7.5, y: 8.8))
        bolt.line(to: geometry.point(x: 9.4, y: 8.8))
        bolt.line(to: geometry.point(x: 8.1, y: 5.5))
        bolt.line(to: geometry.point(x: 11.9, y: 9.4))
        bolt.line(to: geometry.point(x: 10.0, y: 9.4))
        bolt.close()
        bolt.lineJoinStyle = .round
        bolt.lineWidth = max(0.55, 0.55 * geometry.scale)
        NSColor.black.withAlphaComponent(0.55).setStroke()
        NSColor.systemYellow.setFill()
        bolt.fill()
        bolt.stroke()
    }

    private static func drawCriticalBadge(geometry: BatteryIconGeometry) {
        let badgeRect = geometry.rect(x: 15.5, y: 11.9, width: 3.7, height: 3.7)
        let badge = NSBezierPath(ovalIn: badgeRect)
        badge.lineWidth = max(0.65, 0.65 * geometry.scale)
        NSColor.white.withAlphaComponent(0.95).setStroke()
        NSColor.systemRed.setFill()
        badge.fill()
        badge.stroke()
    }
}
