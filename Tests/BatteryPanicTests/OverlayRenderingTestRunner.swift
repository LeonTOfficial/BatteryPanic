import AppKit
import Foundation

@main
struct OverlayRenderingTestRunner {
    private static let canvasSize = NSSize(width: 1920, height: 1080)

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
        pulse: CGFloat
    ) -> NSBitmapImageRep {
        let view = configuredView(mode: mode, percentage: percentage, isTest: isTest)
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
        isTest: Bool
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
