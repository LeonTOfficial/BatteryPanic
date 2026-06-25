import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputURL = root.appendingPathComponent("Resources/DMGBackground.png")
let size = NSSize(width: 680, height: 420)

let image = NSImage(size: size)
image.lockFocus()

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
    let rect = bounds.insetBy(dx: 28 + progress * 155, dy: 28 + progress * 78)
    let path = NSBezierPath(roundedRect: rect, xRadius: 38, yRadius: 38)
    path.lineWidth = 2
    NSColor.systemRed.withAlphaComponent((1 - progress) * 0.10).setStroke()
    path.stroke()
}

drawText(
    "Battery Panic",
    at: NSPoint(x: 46, y: 334),
    font: .systemFont(ofSize: 34, weight: .bold),
    color: .white
)
drawText(
    "Drag the app into Applications",
    at: NSPoint(x: 48, y: 302),
    font: .systemFont(ofSize: 17, weight: .medium),
    color: NSColor.white.withAlphaComponent(0.70)
)

drawInstallArrow(from: NSPoint(x: 278, y: 192), to: NSPoint(x: 405, y: 192))

drawText(
    "1. Drag Battery Panic",
    at: NSPoint(x: 114, y: 78),
    font: .systemFont(ofSize: 14, weight: .semibold),
    color: NSColor.white.withAlphaComponent(0.82)
)
drawText(
    "2. Drop it on Applications",
    at: NSPoint(x: 403, y: 78),
    font: .systemFont(ofSize: 14, weight: .semibold),
    color: NSColor.white.withAlphaComponent(0.82)
)

let noteRect = NSRect(x: 46, y: 26, width: 588, height: 32)
NSColor.white.withAlphaComponent(0.08).setFill()
NSBezierPath(roundedRect: noteRect, xRadius: 12, yRadius: 12).fill()
drawText(
    "If macOS blocks the first launch, open Privacy & Security and click Open Anyway.",
    at: NSPoint(x: 64, y: 35),
    font: .systemFont(ofSize: 12, weight: .medium),
    color: NSColor.white.withAlphaComponent(0.70)
)

image.unlockFocus()

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("Could not render DMG background")
}
try png.write(to: outputURL)
print("Created \(outputURL.path)")

private func drawInstallArrow(from start: NSPoint, to end: NSPoint) {
    let path = NSBezierPath()
    path.move(to: start)
    path.line(to: end)
    path.lineWidth = 5
    path.lineCapStyle = .round
    NSColor.systemRed.withAlphaComponent(0.88).setStroke()
    path.stroke()

    let head = NSBezierPath()
    head.move(to: end)
    head.line(to: NSPoint(x: end.x - 18, y: end.y + 13))
    head.line(to: NSPoint(x: end.x - 18, y: end.y - 13))
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
