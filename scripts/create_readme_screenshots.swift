import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDir = root.appendingPathComponent("docs/screenshots")
let muted = NSColor(calibratedWhite: 0.72, alpha: 1)
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

try save(drawStatusBarPreview(), name: "status-bar-preview.png")
try save(drawSettingsPreview(), name: "settings-preview.png")
try save(drawOverlayPreview(), name: "overlay-preview.png")

print("Created README screenshot previews in \(outputDir.path)")

private func save(_ image: NSImage, name: String) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Could not render \(name)")
    }
    try png.write(to: outputDir.appendingPathComponent(name))
}

private func drawStatusBarPreview() -> NSImage {
    let image = NSImage(size: NSSize(width: 1200, height: 520))
    image.lockFocus()
    fill(NSRect(x: 0, y: 0, width: 1200, height: 520), color: NSColor(calibratedWhite: 0.08, alpha: 1))
    rounded(NSRect(x: 90, y: 340, width: 1020, height: 54), radius: 18, color: NSColor(calibratedWhite: 0.14, alpha: 1))
    drawText("Battery Panic menu bar states", x: 90, y: 90, size: 42, weight: .bold, color: .white)
    drawText("Healthy, warning, critical, and charging states fit quietly into the macOS menu bar.", x: 92, y: 145, size: 20, weight: .regular, color: muted)

    drawState(x: 210, y: 356, color: .systemGreen, label: "82%")
    drawState(x: 420, y: 356, color: .systemOrange, label: "18%")
    drawState(x: 630, y: 356, color: .systemRed, label: "! 9%")
    drawState(x: 840, y: 356, color: .systemGreen, label: "64%", bolt: true)
    image.unlockFocus()
    return image
}

private func drawSettingsPreview() -> NSImage {
    let image = NSImage(size: NSSize(width: 1200, height: 760))
    image.lockFocus()
    fill(NSRect(x: 0, y: 0, width: 1200, height: 760), color: NSColor(calibratedWhite: 0.10, alpha: 1))
    rounded(NSRect(x: 300, y: 80, width: 600, height: 600), radius: 18, color: NSColor(calibratedWhite: 0.18, alpha: 1))
    drawText("Battery Panic", x: 340, y: 130, size: 34, weight: .bold, color: .white)
    drawText("Settings", x: 342, y: 170, size: 18, weight: .medium, color: muted)
    section(title: "Battery threshold", body: "Warn below 10%", y: 230)
    section(title: "Pulsing overlay", body: "Speed 1.0x  /  Intensity 100%  /  Preview 8s", y: 345)
    section(title: "Audio warning alerts", body: "Sound: Battery Panic Siren  /  Test Sound", y: 460)
    drawText("Created by Leon.T  -  GitHub: LeonTOfficial", x: 340, y: 620, size: 16, weight: .medium, color: .linkColor)
    image.unlockFocus()
    return image
}

private func drawOverlayPreview() -> NSImage {
    let image = NSImage(size: NSSize(width: 1200, height: 700))
    image.lockFocus()
    fill(NSRect(x: 0, y: 0, width: 1200, height: 700), color: NSColor(calibratedRed: 0.07, green: 0.10, blue: 0.12, alpha: 1))
    for step in 0..<90 {
        let progress = CGFloat(step) / 90.0
        let rect = NSRect(x: 36 + progress * 115, y: 36 + progress * 68, width: 1128 - progress * 230, height: 628 - progress * 136)
        strokeRounded(rect, radius: 32, color: NSColor.systemRed.withAlphaComponent((1 - progress) * 0.22), width: 3)
    }
    rounded(NSRect(x: 392, y: 294, width: 416, height: 112), radius: 42, color: NSColor(calibratedWhite: 0.10, alpha: 0.94))
    strokeRounded(NSRect(x: 392, y: 294, width: 416, height: 112), radius: 42, color: NSColor.systemRed.withAlphaComponent(0.88), width: 2)
    drawBattery(x: 438, y: 335, color: .systemRed)
    drawText("BATTERY PANIC", x: 530, y: 304, size: 14, weight: .black, color: NSColor.systemRed.withAlphaComponent(0.78))
    drawText("Low power: 9%", x: 530, y: 330, size: 32, weight: .black, color: .systemRed)
    drawText("Plug in your charger to dismiss this alert", x: 532, y: 372, size: 16, weight: .medium, color: NSColor.white.withAlphaComponent(0.72))
    image.unlockFocus()
    return image
}

private func section(title: String, body: String, y: CGFloat) {
    rounded(NSRect(x: 340, y: y, width: 520, height: 86), radius: 12, color: NSColor(calibratedWhite: 0.23, alpha: 1))
    drawText(title, x: 364, y: y + 24, size: 17, weight: .semibold, color: .white)
    drawText(body, x: 364, y: y + 52, size: 15, weight: .regular, color: muted)
}

private func drawState(x: CGFloat, y: CGFloat, color: NSColor, label: String, bolt: Bool = false) {
    drawBattery(x: x, y: y, color: color)
    if bolt {
        drawText("⌁", x: x + 30, y: y - 5, size: 20, weight: .bold, color: color)
    }
    drawText(label, x: x + 56, y: y - 2, size: 22, weight: .semibold, color: .white)
}

private func drawBattery(x: CGFloat, y: CGFloat, color: NSColor) {
    strokeRounded(NSRect(x: x, y: y, width: 40, height: 22), radius: 5, color: color, width: 3)
    rounded(NSRect(x: x + 44, y: y + 7, width: 5, height: 8), radius: 2, color: color)
    rounded(NSRect(x: x + 7, y: y + 6, width: 13, height: 10), radius: 2, color: color.withAlphaComponent(0.72))
}

private func drawText(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
    NSAttributedString(
        string: text,
        attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ]
    ).draw(at: NSPoint(x: x, y: y))
}

private func fill(_ rect: NSRect, color: NSColor) {
    color.setFill()
    rect.fill()
}

private func rounded(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

private func strokeRounded(_ rect: NSRect, radius: CGFloat, color: NSColor, width: CGFloat) {
    color.setStroke()
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.lineWidth = width
    path.stroke()
}
