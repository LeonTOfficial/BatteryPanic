import AppKit
import Foundation

@main
struct MenuBarIconTestRunner {
    static func main() {
        var suite = IconTestSuite()
        let menuGeometry = BatteryIconGeometry(size: NSSize(width: 22, height: 18))
        let headerGeometry = BatteryIconGeometry(size: NSSize(width: 36, height: 28))

        suite.expect("empty battery has no artificial fill", menuGeometry.fillRect(percentage: 0).width == 0)
        suite.expect(
            "half-full battery uses half of its interior",
            approximatelyEqual(
                menuGeometry.fillRect(percentage: 50).width,
                menuGeometry.innerRect.width / 2
            )
        )
        suite.expect(
            "full battery fills its complete interior",
            approximatelyEqual(
                menuGeometry.fillRect(percentage: 100).width,
                menuGeometry.innerRect.width
            )
        )
        suite.expect(
            "percentages are safely clamped",
            menuGeometry.fillRect(percentage: -10).width == 0
                && approximatelyEqual(
                    menuGeometry.fillRect(percentage: 140).width,
                    menuGeometry.innerRect.width
                )
        )
        suite.expect(
            "larger header icon keeps a uniform aspect ratio",
            approximatelyEqual(headerGeometry.scale, 28 / 18)
        )

        let emptyImage = icon(level: .unavailable, percentage: 0)
        let fullImage = icon(level: .healthy, percentage: 100)
        let chargingImage = icon(level: .charging, percentage: 80)
        suite.expect("empty icon renders visible outline pixels", opaquePixelCount(in: emptyImage) > 20)
        suite.expect("full icon renders more pixels than empty icon", opaquePixelCount(in: fullImage) > opaquePixelCount(in: emptyImage))
        suite.expect("charging icon renders its yellow bolt", yellowPixelCount(in: chargingImage) > 0)

        if let outputIndex = CommandLine.arguments.firstIndex(of: "--preview-output"),
           CommandLine.arguments.indices.contains(outputIndex + 1) {
            let outputURL = URL(fileURLWithPath: CommandLine.arguments[outputIndex + 1])
            do {
                try renderPreviewSheet().write(to: outputURL)
                print("Wrote icon preview: \(outputURL.path)")
            } catch {
                suite.expect("writes icon preview sheet", false)
            }
        }

        suite.finish()
    }

    private static func icon(level: BatteryStatusLevel, percentage: Int) -> NSImage {
        let appearance = appearance(level: level)
        return MenuBarIconFactory.image(appearance: appearance, percentage: percentage)
    }

    private static func appearance(level: BatteryStatusLevel) -> BatteryStatusAppearance {
        switch level {
        case .healthy:
            return BatteryStatusAppearance(level: level, color: .systemGreen, title: "", subtitle: "", showsBolt: false, showsCriticalDot: false)
        case .warning:
            return BatteryStatusAppearance(level: level, color: .systemOrange, title: "", subtitle: "", showsBolt: false, showsCriticalDot: false)
        case .critical:
            return BatteryStatusAppearance(level: level, color: .systemRed, title: "", subtitle: "", showsBolt: false, showsCriticalDot: true)
        case .charging:
            return BatteryStatusAppearance(level: level, color: .systemGreen, title: "", subtitle: "", showsBolt: true, showsCriticalDot: false)
        case .unavailable:
            return BatteryStatusAppearance(level: level, color: .secondaryLabelColor, title: "", subtitle: "", showsBolt: false, showsCriticalDot: false)
        }
    }

    private static func rasterized(_ image: NSImage, scale: CGFloat = 2) -> NSBitmapImageRep {
        let pixelWidth = Int(image.size.width * scale)
        let pixelHeight = Int(image.size.height * scale)
        let representation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        representation.size = image.size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)
        image.draw(in: NSRect(origin: .zero, size: image.size))
        NSGraphicsContext.current?.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()
        return representation
    }

    private static func opaquePixelCount(in image: NSImage) -> Int {
        let representation = rasterized(image)
        var count = 0
        for y in 0..<representation.pixelsHigh {
            for x in 0..<representation.pixelsWide {
                if (representation.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.12 {
                    count += 1
                }
            }
        }
        return count
    }

    private static func yellowPixelCount(in image: NSImage) -> Int {
        let representation = rasterized(image)
        var count = 0
        for y in 0..<representation.pixelsHigh {
            for x in 0..<representation.pixelsWide {
                guard let color = representation.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
                    continue
                }
                if color.redComponent > 0.7,
                   color.greenComponent > 0.55,
                   color.blueComponent < 0.45,
                   color.alphaComponent > 0.5 {
                    count += 1
                }
            }
        }
        return count
    }

    private static func renderPreviewSheet() throws -> Data {
        let size = NSSize(width: 960, height: 420)
        let scale: CGFloat = 2
        let representation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * scale),
            pixelsHigh: Int(size.height * scale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        representation.size = size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)
        NSColor(calibratedWhite: 0.055, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

        drawLabel("Battery Panic menu icon states", at: NSPoint(x: 42, y: 360), size: 26, color: .white, weight: .bold)
        drawLabel("Accurate fill, uniform scaling, charging bolt and critical badge", at: NSPoint(x: 42, y: 330), size: 14, color: NSColor.white.withAlphaComponent(0.62), weight: .regular)

        let states: [(String, BatteryStatusLevel, Int)] = [
            ("Empty", .unavailable, 0),
            ("Critical", .critical, 2),
            ("Low", .critical, 10),
            ("Warning", .warning, 25),
            ("Healthy", .healthy, 50),
            ("Healthy", .healthy, 80),
            ("Full", .healthy, 100),
            ("Charging", .charging, 80)
        ]

        for (index, state) in states.enumerated() {
            let x = 44 + CGFloat(index) * 114
            let cardRect = NSRect(x: x, y: 118, width: 96, height: 170)
            NSColor(calibratedWhite: 0.105, alpha: 1).setFill()
            NSBezierPath(roundedRect: cardRect, xRadius: 8, yRadius: 8).fill()

            let preview = MenuBarIconFactory.image(
                appearance: appearance(level: state.1),
                percentage: state.2,
                size: NSSize(width: 66, height: 54)
            )
            preview.draw(in: NSRect(x: x + 15, y: 205, width: 66, height: 54))
            drawLabel("\(state.2)%", at: NSPoint(x: x + 16, y: 166), size: 19, color: .white, weight: .semibold)
            drawLabel(state.0, at: NSPoint(x: x + 16, y: 143), size: 12, color: NSColor.white.withAlphaComponent(0.58), weight: .medium)

            let actual = MenuBarIconFactory.image(
                appearance: appearance(level: state.1),
                percentage: state.2
            )
            actual.draw(in: NSRect(x: x + 37, y: 126, width: 22, height: 18))
        }

        NSGraphicsContext.current?.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw PreviewError.encodingFailed
        }
        return data
    }

    private static func drawLabel(
        _ text: String,
        at point: NSPoint,
        size: CGFloat,
        color: NSColor,
        weight: NSFont.Weight
    ) {
        (text as NSString).draw(
            at: point,
            withAttributes: [
                .font: NSFont.systemFont(ofSize: size, weight: weight),
                .foregroundColor: color
            ]
        )
    }

    private static func approximatelyEqual(_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
        abs(lhs - rhs) < 0.001
    }

    private enum PreviewError: Error {
        case encodingFailed
    }
}

private struct IconTestSuite {
    private var passed = 0
    private var failed = 0

    mutating func expect(_ name: String, _ condition: Bool) {
        if condition {
            passed += 1
            print("PASS: \(name)")
        } else {
            failed += 1
            print("FAIL: \(name)")
        }
    }

    func finish() -> Never {
        print("MenuBarIcon tests: \(passed) passed, \(failed) failed")
        exit(failed == 0 ? 0 : 1)
    }
}
