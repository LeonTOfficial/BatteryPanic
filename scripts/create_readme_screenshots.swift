import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDir = root.appendingPathComponent("docs/screenshots")
let muted = NSColor(calibratedWhite: 0.72, alpha: 1)
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

try save(drawStatusBarPreview(), name: "status-bar-preview.png")
try saveJPEG(drawSettingsPreview(), name: "settings-preview.jpg", quality: 0.78)
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

private func saveJPEG(_ image: NSImage, name: String, quality: CGFloat) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let jpg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
    else {
        fatalError("Could not render \(name)")
    }
    try jpg.write(to: outputDir.appendingPathComponent(name))
}

private func drawStatusBarPreview() -> NSImage {
    let image = NSImage(size: NSSize(width: 1200, height: 520))
    image.lockFocus()
    fill(NSRect(x: 0, y: 0, width: 1200, height: 520), color: NSColor(calibratedWhite: 0.08, alpha: 1))
    rounded(NSRect(x: 90, y: 340, width: 1020, height: 54), radius: 18, color: NSColor(calibratedWhite: 0.14, alpha: 1))
    drawText("Battery Panic menu bar states", x: 90, y: 145, size: 42, weight: .bold, color: .white)
    drawText("Healthy, warning, critical, and charging states fit quietly into the macOS menu bar.", x: 92, y: 100, size: 20, weight: .regular, color: muted)

    drawState(x: 210, y: 356, color: .systemGreen, label: "82%")
    drawState(x: 420, y: 356, color: .systemOrange, label: "18%")
    drawState(x: 630, y: 356, color: .systemRed, label: "9%")
    drawState(x: 840, y: 356, color: .systemGreen, label: "64%", bolt: true)
    image.unlockFocus()
    return image
}

private func drawSettingsPreview() -> NSImage {
    let image = NSImage(size: NSSize(width: 1200, height: 820))
    image.lockFocus()
    fill(NSRect(x: 0, y: 0, width: 1200, height: 820), color: NSColor(calibratedWhite: 0.08, alpha: 1))
    rounded(NSRect(x: 250, y: 70, width: 700, height: 680), radius: 28, color: NSColor(calibratedWhite: 0.95, alpha: 1))
    strokeRounded(NSRect(x: 250, y: 70, width: 700, height: 680), radius: 28, color: NSColor.white.withAlphaComponent(0.18), width: 1)

    drawWindowDots(x: 276, y: 720)
    drawSmallIcon(x: 292, y: 646)
    drawText("Battery Panic", x: 350, y: 670, size: 32, weight: .bold, color: NSColor(calibratedWhite: 0.10, alpha: 1))
    drawText("A visible red warning when your MacBook battery needs attention.", x: 352, y: 642, size: 16, weight: .regular, color: NSColor(calibratedWhite: 0.42, alpha: 1))

    settingsCard(title: "Battery threshold", body: "Default 10%. The alert appears only while unplugged.", y: 540)
    drawSlider(x: 404, y: 570, width: 320, fill: 0.20, color: .systemRed)
    drawText("10%", x: 754, y: 564, size: 21, weight: .semibold, color: NSColor(calibratedWhite: 0.12, alpha: 1))

    settingsCard(title: "Pulsing overlay", body: "Live preview, pulse speed, and intensity controls.", y: 378, height: 138)
    rounded(NSRect(x: 396, y: 404, width: 430, height: 58), radius: 16, color: NSColor(calibratedWhite: 0.10, alpha: 1))
    for step in 0..<14 {
        let progress = CGFloat(step) / 14.0
        strokeRounded(NSRect(x: 408 + progress * 28, y: 414 + progress * 8, width: 406 - progress * 56, height: 38 - progress * 16), radius: 14, color: NSColor.systemRed.withAlphaComponent((1 - progress) * 0.16), width: 2)
    }
    drawText("Live overlay preview", x: 430, y: 435, size: 15, weight: .bold, color: .systemRed)
    drawText("1.0x  /  100%", x: 662, y: 435, size: 15, weight: .medium, color: NSColor.white.withAlphaComponent(0.72))
    drawSlider(x: 404, y: 388, width: 330, fill: 0.48, color: .systemRed)
    drawSlider(x: 404, y: 368, width: 330, fill: 0.62, color: .systemRed)

    settingsCard(title: "Audio warning alerts", body: "Choose a sound and test it before relying on it.", y: 264)
    rounded(NSRect(x: 404, y: 296, width: 190, height: 30), radius: 8, color: NSColor(calibratedWhite: 0.88, alpha: 1))
    drawText("Battery Panic Siren", x: 420, y: 303, size: 14, weight: .medium, color: NSColor(calibratedWhite: 0.18, alpha: 1))
    rounded(NSRect(x: 612, y: 294, width: 98, height: 34), radius: 9, color: NSColor.systemRed.withAlphaComponent(0.13))
    drawText("Test Sound", x: 626, y: 303, size: 14, weight: .semibold, color: .systemRed)

    settingsCard(title: "General", body: "Start at login and pause the warning when needed.", y: 150)
    drawToggle(x: 406, y: 184, enabled: true)
    drawText("Start at login", x: 464, y: 189, size: 15, weight: .medium, color: NSColor(calibratedWhite: 0.16, alpha: 1))
    drawText("Created by Leon.T  -  GitHub: LeonTOfficial", x: 340, y: 105, size: 15, weight: .medium, color: .linkColor)
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
    rounded(NSRect(x: 340, y: 294, width: 520, height: 112), radius: 42, color: NSColor(calibratedWhite: 0.10, alpha: 0.94))
    strokeRounded(NSRect(x: 340, y: 294, width: 520, height: 112), radius: 42, color: NSColor.systemRed.withAlphaComponent(0.88), width: 2)
    drawBattery(x: 390, y: 335, color: .systemRed)
    drawText("BATTERY PANIC", x: 490, y: 372, size: 14, weight: .black, color: NSColor.systemRed.withAlphaComponent(0.78))
    drawText("Low power: 9%", x: 490, y: 330, size: 32, weight: .black, color: .systemRed)
    drawText("Plug in your charger to dismiss this alert", x: 492, y: 304, size: 16, weight: .medium, color: NSColor.white.withAlphaComponent(0.72))
    image.unlockFocus()
    return image
}

private func settingsCard(title: String, body: String, y: CGFloat, height: CGFloat = 92) {
    rounded(NSRect(x: 300, y: y, width: 600, height: height), radius: 16, color: NSColor(calibratedWhite: 0.985, alpha: 1))
    strokeRounded(NSRect(x: 300, y: y, width: 600, height: height), radius: 16, color: NSColor(calibratedWhite: 0.78, alpha: 1), width: 1)
    drawText(title, x: 326, y: y + height - 34, size: 18, weight: .semibold, color: NSColor(calibratedWhite: 0.10, alpha: 1))
    drawText(body, x: 326, y: y + height - 58, size: 14, weight: .regular, color: NSColor(calibratedWhite: 0.42, alpha: 1))
}

private func drawWindowDots(x: CGFloat, y: CGFloat) {
    rounded(NSRect(x: x, y: y, width: 12, height: 12), radius: 6, color: .systemRed)
    rounded(NSRect(x: x + 22, y: y, width: 12, height: 12), radius: 6, color: .systemYellow)
    rounded(NSRect(x: x + 44, y: y, width: 12, height: 12), radius: 6, color: NSColor(calibratedWhite: 0.80, alpha: 1))
}

private func drawSmallIcon(x: CGFloat, y: CGFloat) {
    rounded(NSRect(x: x, y: y, width: 42, height: 42), radius: 10, color: NSColor(calibratedWhite: 0.09, alpha: 1))
    strokeRounded(NSRect(x: x + 6, y: y + 6, width: 30, height: 30), radius: 7, color: .systemRed, width: 2)
    drawBattery(x: x + 12, y: y + 18, color: .systemRed)
}

private func drawSlider(x: CGFloat, y: CGFloat, width: CGFloat, fill: CGFloat, color: NSColor) {
    rounded(NSRect(x: x, y: y, width: width, height: 5), radius: 2.5, color: NSColor(calibratedWhite: 0.82, alpha: 1))
    rounded(NSRect(x: x, y: y, width: width * fill, height: 5), radius: 2.5, color: color)
    rounded(NSRect(x: x + width * fill - 8, y: y - 6, width: 17, height: 17), radius: 8.5, color: .white)
    strokeRounded(NSRect(x: x + width * fill - 8, y: y - 6, width: 17, height: 17), radius: 8.5, color: NSColor(calibratedWhite: 0.70, alpha: 1), width: 1)
}

private func drawToggle(x: CGFloat, y: CGFloat, enabled: Bool) {
    let color = enabled ? NSColor.systemGreen : NSColor(calibratedWhite: 0.70, alpha: 1)
    rounded(NSRect(x: x, y: y, width: 44, height: 26), radius: 13, color: color)
    rounded(NSRect(x: x + (enabled ? 21 : 3), y: y + 3, width: 20, height: 20), radius: 10, color: .white)
}

private func section(title: String, body: String, y: CGFloat) {
    rounded(NSRect(x: 340, y: y, width: 520, height: 86), radius: 12, color: NSColor(calibratedWhite: 0.23, alpha: 1))
    drawText(title, x: 364, y: y + 52, size: 17, weight: .semibold, color: .white)
    drawText(body, x: 364, y: y + 24, size: 15, weight: .regular, color: muted)
}

private func drawState(x: CGFloat, y: CGFloat, color: NSColor, label: String, bolt: Bool = false) {
    drawBattery(x: x, y: y, color: color)
    if bolt {
        drawText("⚡", x: x + 30, y: y - 5, size: 20, weight: .bold, color: color)
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
