import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetURL = root.appendingPathComponent("Resources/BatteryPanic.iconset")
let outputURL = root.appendingPathComponent("Resources/AppIcon.icns")

try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let variants: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for variant in variants {
    let image = makeIcon(size: variant.1)
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Could not render icon")
    }
    try png.write(to: iconsetURL.appendingPathComponent(variant.0))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
    "-c",
    "icns",
    iconsetURL.path,
    "-o",
    outputURL.path
]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    fatalError("iconutil failed")
}

try? FileManager.default.removeItem(at: iconsetURL)
print("Created \(outputURL.path)")

private func makeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.22
    let background = NSBezierPath(roundedRect: bounds.insetBy(dx: size * 0.06, dy: size * 0.06), xRadius: radius, yRadius: radius)
    NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.09, alpha: 1).setFill()
    background.fill()

    let outerGlow = NSBezierPath(roundedRect: bounds.insetBy(dx: size * 0.09, dy: size * 0.09), xRadius: radius * 0.86, yRadius: radius * 0.86)
    outerGlow.lineWidth = max(2, size * 0.026)
    NSColor.systemRed.withAlphaComponent(0.64).setStroke()
    outerGlow.stroke()

    let innerGlow = NSBezierPath(roundedRect: bounds.insetBy(dx: size * 0.145, dy: size * 0.145), xRadius: radius * 0.66, yRadius: radius * 0.66)
    innerGlow.lineWidth = max(1.5, size * 0.014)
    NSColor.systemRed.withAlphaComponent(0.22).setStroke()
    innerGlow.stroke()

    let body = NSRect(x: size * 0.22, y: size * 0.38, width: size * 0.49, height: size * 0.24)
    let bodyPath = NSBezierPath(roundedRect: body, xRadius: size * 0.052, yRadius: size * 0.052)
    bodyPath.lineWidth = max(2, size * 0.034)
    NSColor.systemRed.setStroke()
    bodyPath.stroke()

    let nub = NSBezierPath(
        roundedRect: NSRect(x: body.maxX + size * 0.036, y: body.midY - size * 0.052, width: size * 0.055, height: size * 0.104),
        xRadius: size * 0.02,
        yRadius: size * 0.02
    )
    NSColor.systemRed.setFill()
    nub.fill()

    let lowFill = NSBezierPath(
        roundedRect: NSRect(x: body.minX + size * 0.055, y: body.minY + size * 0.055, width: size * 0.11, height: body.height - size * 0.11),
        xRadius: size * 0.02,
        yRadius: size * 0.02
    )
    NSColor.systemRed.withAlphaComponent(0.78).setFill()
    lowFill.fill()

    let pulseLine = NSBezierPath(roundedRect: NSRect(x: size * 0.27, y: size * 0.26, width: size * 0.42, height: size * 0.035), xRadius: size * 0.017, yRadius: size * 0.017)
    NSColor.systemRed.withAlphaComponent(0.38).setFill()
    pulseLine.fill()

    let smallPulseLine = NSBezierPath(
        roundedRect: NSRect(x: size * 0.34, y: size * 0.72, width: size * 0.28, height: size * 0.022),
        xRadius: size * 0.011,
        yRadius: size * 0.011
    )
    NSColor.systemRed.withAlphaComponent(0.20).setFill()
    smallPulseLine.fill()

    image.unlockFocus()
    return image
}
