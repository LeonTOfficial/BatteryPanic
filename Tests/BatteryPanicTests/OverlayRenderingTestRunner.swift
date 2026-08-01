import AppKit
import Foundation

@main
struct OverlayRenderingTestRunner {
    private static let canvasSize = NSSize(width: 1920, height: 1080)
    private static let compactCanvasSize = NSSize(width: 1280, height: 800)

    static func main() throws {
        _ = NSApplication.shared
        let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/overlay-previews", isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let cases: [(name: String, mode: OverlayDisplayMode, percentage: Int, isTest: Bool)] = [
            ("low-battery", .lowBattery, 10, false),
            ("test-alarm", .lowBattery, 10, true),
            ("critical-battery", .criticalBattery, 2, false),
            ("charging-reminder", .chargeReminder, 80, false),
            ("charging-reminder-full", .chargeReminder, 100, false),
        ]

        var suite = TestSuite()
        for testCase in cases {
            let accumulated = render(
                mode: testCase.mode,
                percentage: testCase.percentage,
                isTest: testCase.isTest,
                pulses: [0.08, 0.34, 0.67, 0.92]
            )
            let fresh = render(
                mode: testCase.mode,
                percentage: testCase.percentage,
                isTest: testCase.isTest,
                pulses: [0.92]
            )
            let lowPulse = render(
                mode: testCase.mode,
                percentage: testCase.percentage,
                isTest: testCase.isTest,
                pulses: [0.08]
            )

            suite.expect(
                "\(testCase.name) redraw replaces the previous frame",
                pixelData(for: accumulated) == pixelData(for: fresh)
            )
            suite.expect(
                "\(testCase.name) renders visible pixels",
                visiblePixelCount(in: fresh) > 10_000
            )
            suite.expect(
                "\(testCase.name) pulse changes rendered pixels",
                pixelData(for: lowPulse) != pixelData(for: fresh)
            )

            let preview = renderPreview(
                mode: testCase.mode,
                percentage: testCase.percentage,
                isTest: testCase.isTest,
                pulse: 0.92
            )
            let png = preview.representation(using: .png, properties: [:])
            suite.expect(
                "\(testCase.name) preview encodes at the expected size",
                preview.size == canvasSize
                    && preview.pixelsWide >= Int(canvasSize.width)
                    && preview.pixelsHigh >= Int(canvasSize.height)
                    && (png?.count ?? 0) > 10_000
            )

            if let png {
                try png.write(to: outputDirectory.appendingPathComponent("\(testCase.name).png"))
            }

            assertTextSpacing(
                in: preview,
                canvasSize: canvasSize,
                mode: testCase.mode,
                name: testCase.name,
                suite: &suite
            )

            let compactPreview = renderPreview(
                mode: testCase.mode,
                percentage: testCase.percentage,
                isTest: testCase.isTest,
                pulse: 0.92,
                canvasSize: compactCanvasSize
            )
            assertTextSpacing(
                in: compactPreview,
                canvasSize: compactCanvasSize,
                mode: testCase.mode,
                name: "\(testCase.name) at 1280x800",
                suite: &suite
            )

            if testCase.name == "test-alarm",
               let png = compactPreview.representation(using: .png, properties: [:]) {
                try png.write(to: outputDirectory.appendingPathComponent("test-alarm-1280x800.png"))
            }
        }

        suite.finish()
    }

    private static func render(
        mode: OverlayDisplayMode,
        percentage: Int,
        isTest: Bool,
        pulses: [CGFloat]
    ) -> NSBitmapImageRep {
        let width = Int(canvasSize.width)
        let height = Int(canvasSize.height)
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            fatalError("Could not create overlay rendering context")
        }

        if let data = bitmap.bitmapData {
            data.initialize(repeating: 0, count: bitmap.bytesPerRow * bitmap.pixelsHigh)
        }

        let view = configuredView(mode: mode, percentage: percentage, isTest: isTest)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        for pulse in pulses {
            view.pulseValue = pulse
            view.draw(view.bounds)
        }
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        return bitmap
    }

    private static func renderPreview(
        mode: OverlayDisplayMode,
        percentage: Int,
        isTest: Bool,
        pulse: CGFloat,
        canvasSize: NSSize = canvasSize
    ) -> NSBitmapImageRep {
        let view = configuredView(
            mode: mode,
            percentage: percentage,
            isTest: isTest,
            canvasSize: canvasSize
        )
        view.pulseValue = pulse
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            fatalError("Could not create overlay preview bitmap")
        }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        return bitmap
    }

    private static func configuredView(
        mode: OverlayDisplayMode,
        percentage: Int,
        isTest: Bool,
        canvasSize: NSSize = canvasSize
    ) -> OverlayView {
        let view = OverlayView(frame: NSRect(origin: .zero, size: canvasSize))
        view.percentage = percentage
        view.timeRemainingText = mode == .criticalBattery ? "About 8 minutes remaining" : nil
        view.pulseEnabled = true
        view.pulseIntensity = mode == .criticalBattery ? 1.35 : 1.0
        view.displayMode = mode
        view.isTest = isTest
        return view
    }

    private static func assertTextSpacing(
        in bitmap: NSBitmapImageRep,
        canvasSize: NSSize,
        mode: OverlayDisplayMode,
        name: String,
        suite: inout TestSuite
    ) {
        let cardRect = warningCardRect(canvasSize: canvasSize, mode: mode)
        let scanRect = NSRect(
            x: cardRect.minX + 112,
            y: cardRect.minY + 8,
            width: cardRect.width - 132,
            height: cardRect.height - 16
        )
        let accentBands = occupiedRowBands(in: bitmap, scanRect: scanRect) { red, green, blue in
            switch mode {
            case .chargeReminder:
                return green > 125 && blue > 125 && green > red + 35 && blue > red + 35
            case .criticalBattery, .lowBattery:
                return red > 150 && red > green + 55 && red > blue + 55
            }
        }
        let subtitleBands = occupiedRowBands(in: bitmap, scanRect: scanRect) { red, green, blue in
            let strongest = max(red, green, blue)
            let weakest = min(red, green, blue)
            return weakest > 115 && strongest - weakest < 45
        }

        if accentBands.count != 2 || subtitleBands.count != 1 {
            print("LAYOUT: \(name) accent=\(accentBands) subtitle=\(subtitleBands)")
        }

        suite.expect("\(name) keeps eyebrow and title in separate rows", accentBands.count == 2)
        suite.expect("\(name) renders one subtitle row", subtitleBands.count == 1)

        if accentBands.count == 2 {
            let scaleY = CGFloat(bitmap.pixelsHigh) / bitmap.size.height
            let accentGap = CGFloat(gap(between: accentBands[0], and: accentBands[1])) / scaleY
            suite.expect(
                "\(name) leaves visible space between eyebrow and title",
                accentGap >= 8
            )
        }

        if accentBands.count == 2, let subtitleBand = subtitleBands.first {
            let scaleY = CGFloat(bitmap.pixelsHigh) / bitmap.size.height
            let nearestAccentGap = CGFloat(accentBands
                .map { gap(between: $0, and: subtitleBand) }
                .min() ?? 0) / scaleY
            suite.expect(
                "\(name) keeps the subtitle close to the title",
                nearestAccentGap >= 4 && nearestAccentGap <= 18
            )
        }
    }

    private static func warningCardRect(canvasSize: NSSize, mode: OverlayDisplayMode) -> NSRect {
        let width = min(
            max(canvasSize.width * 0.30, mode == .chargeReminder ? 430 : 470),
            mode == .chargeReminder ? 520 : 560
        )
        let height: CGFloat = 132
        return NSRect(
            x: (canvasSize.width - width) / 2,
            y: (canvasSize.height - height) / 2,
            width: width,
            height: height
        )
    }

    private static func occupiedRowBands(
        in bitmap: NSBitmapImageRep,
        scanRect: NSRect,
        matches: (Int, Int, Int) -> Bool
    ) -> [ClosedRange<Int>] {
        guard let bytes = bitmap.bitmapData, bitmap.samplesPerPixel >= 4 else { return [] }

        let scaleX = CGFloat(bitmap.pixelsWide) / bitmap.size.width
        let scaleY = CGFloat(bitmap.pixelsHigh) / bitmap.size.height
        let minX = max(0, Int((scanRect.minX * scaleX).rounded(.down)))
        let maxX = min(bitmap.pixelsWide - 1, Int((scanRect.maxX * scaleX).rounded(.up)))
        let minY = max(0, Int((scanRect.minY * scaleY).rounded(.down)))
        let maxY = min(bitmap.pixelsHigh - 1, Int((scanRect.maxY * scaleY).rounded(.up)))
        var occupiedRows: [Int] = []

        for y in minY...maxY {
            var matchingPixels = 0
            for x in minX...maxX {
                let offset = (y * bitmap.bytesPerRow) + (x * bitmap.samplesPerPixel)
                let red = Int(bytes[offset])
                let green = Int(bytes[offset + 1])
                let blue = Int(bytes[offset + 2])
                let alpha = Int(bytes[offset + 3])
                if alpha > 100, matches(red, green, blue) {
                    matchingPixels += 1
                }
            }
            if matchingPixels >= 3 {
                occupiedRows.append(y)
            }
        }

        return occupiedRows.reduce(into: []) { bands, row in
            guard let last = bands.last else {
                bands.append(row...row)
                return
            }
            if row == last.upperBound + 1 {
                bands[bands.count - 1] = last.lowerBound...row
            } else {
                bands.append(row...row)
            }
        }
    }

    private static func gap(between first: ClosedRange<Int>, and second: ClosedRange<Int>) -> Int {
        if first.upperBound < second.lowerBound {
            return second.lowerBound - first.upperBound - 1
        }
        if second.upperBound < first.lowerBound {
            return first.lowerBound - second.upperBound - 1
        }
        return 0
    }

    private static func pixelData(for bitmap: NSBitmapImageRep) -> Data {
        guard let bytes = bitmap.bitmapData else { return Data() }
        return Data(bytes: bytes, count: bitmap.bytesPerRow * bitmap.pixelsHigh)
    }

    private static func visiblePixelCount(in bitmap: NSBitmapImageRep) -> Int {
        guard let bytes = bitmap.bitmapData else { return 0 }
        let data = UnsafeBufferPointer(
            start: bytes,
            count: bitmap.bytesPerRow * bitmap.pixelsHigh
        )
        let alphaOffset = bitmap.samplesPerPixel - 1
        return stride(from: alphaOffset, to: data.count, by: bitmap.samplesPerPixel)
            .reduce(into: 0) { count, index in
                if data[index] > 0 {
                    count += 1
                }
            }
    }
}

private struct TestSuite {
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
        print("Overlay rendering tests: \(passed) passed, \(failed) failed")
        exit(failed == 0 ? 0 : 1)
    }
}
