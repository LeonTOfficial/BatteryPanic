import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputURL = root.appendingPathComponent("Resources/DMGBackground.png")
let scale: CGFloat = 2
let logicalSize = NSSize(width: 680, height: 420)
let size = NSSize(width: logicalSize.width * scale, height: logicalSize.height * scale)

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Could not create DMG background bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let bounds = NSRect(origin: .zero, size: size)
NSColor(calibratedRed: 0.075, green: 0.077, blue: 0.090, alpha: 1).setFill()
bounds.fill()

let wash = NSGradient(colors: [
    NSColor.systemRed.withAlphaComponent(0.28),
    NSColor(calibratedRed: 0.075, green: 0.077, blue: 0.090, alpha: 0.0)
])
wash?.draw(in: bounds, angle: 0)

for step in 0..<36 {
    let progress = CGFloat(step) / 36.0
    let rect = bounds.insetBy(dx: px(28 + progress * 145), dy: px(28 + progress * 72))
    let path = NSBezierPath(roundedRect: rect, xRadius: px(34), yRadius: px(34))
    path.lineWidth = px(1)
    NSColor.systemRed.withAlphaComponent((1 - progress) * 0.10).setStroke()
    path.stroke()
}

drawText(
    "Battery Panic",
    at: point(36, 336),
    font: .systemFont(ofSize: px(27), weight: .bold),
    color: .white
)
drawText(
    "Drag the app into Applications",
    at: point(38, 306),
    font: .systemFont(ofSize: px(14), weight: .medium),
    color: NSColor.white.withAlphaComponent(0.70)
)

drawInstallArrow(from: point(284, 208), to: point(400, 208))

drawText(
    "1. Drag Battery Panic",
    at: point(78, 88),
    font: .systemFont(ofSize: px(12), weight: .semibold),
    color: NSColor.white.withAlphaComponent(0.82)
)
drawText(
    "2. Drop it on Applications",
    at: point(382, 88),
    font: .systemFont(ofSize: px(12), weight: .semibold),
    color: NSColor.white.withAlphaComponent(0.82)
)

let noteRect = rect(38, 26, 604, 32)
NSColor.white.withAlphaComponent(0.08).setFill()
NSBezierPath(roundedRect: noteRect, xRadius: px(12), yRadius: px(12)).fill()
drawText(
    "If macOS blocks first launch, open Privacy & Security, scroll down, then click Open Anyway.",
    at: point(55, 36),
    font: .systemFont(ofSize: px(8.8), weight: .medium),
    color: NSColor.white.withAlphaComponent(0.70)
)

NSGraphicsContext.restoreGraphicsState()

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render DMG background")
}
try png.write(to: outputURL)
print("Created \(outputURL.path)")

private func drawInstallArrow(from start: NSPoint, to end: NSPoint) {
    let path = NSBezierPath()
    path.move(to: start)
    path.line(to: end)
    path.lineWidth = px(4)
    path.lineCapStyle = .round
    NSColor.systemRed.withAlphaComponent(0.88).setStroke()
    path.stroke()

    let head = NSBezierPath()
    head.move(to: end)
    head.line(to: NSPoint(x: end.x - px(17), y: end.y + px(12)))
    head.line(to: NSPoint(x: end.x - px(17), y: end.y - px(12)))
    head.close()
    NSColor.systemRed.withAlphaComponent(0.88).setFill()
    head.fill()
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

private func px(_ value: CGFloat) -> CGFloat {
    value * scale
}

private func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
    NSPoint(x: px(x), y: px(y))
}

private func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
    NSRect(x: px(x), y: px(y), width: px(width), height: px(height))
}
