import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetURL = FileManager.default.temporaryDirectory.appendingPathComponent("BatteryPanic-\(UUID().uuidString).iconset")
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
    let fallbackPNG = iconsetURL.appendingPathComponent("icon_512x512@2x.png")
    let fallback = Process()
    fallback.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    fallback.arguments = [
        "-s",
        "format",
        "icns",
        fallbackPNG.path,
        "--out",
        outputURL.path
    ]
    try? fallback.run()
    fallback.waitUntilExit()

    try? FileManager.default.removeItem(at: iconsetURL)
    if fallback.terminationStatus == 0 {
        print("Created \(outputURL.path) using sips fallback")
        exit(0)
    } else if FileManager.default.fileExists(atPath: outputURL.path) {
        print("iconutil and sips fallback could not rebuild the icon; kept existing \(outputURL.path)")
        exit(0)
    }
    fatalError("iconutil and sips fallback failed, and no existing AppIcon.icns is available")
}

try? FileManager.default.removeItem(at: iconsetURL)
print("Created \(outputURL.path)")

private func makeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.22
    let background = NSBezierPath(roundedRect: bounds.insetBy(dx: size * 0.055, dy: size * 0.055), xRadius: radius, yRadius: radius)
    NSColor(calibratedRed: 0.055, green: 0.057, blue: 0.065, alpha: 1).setFill()
    background.fill()

    let outerGlow = NSBezierPath(roundedRect: bounds.insetBy(dx: size * 0.11, dy: size * 0.11), xRadius: radius * 0.82, yRadius: radius * 0.82)
    outerGlow.lineWidth = max(2, size * 0.026)
    NSColor.systemRed.withAlphaComponent(0.62).setStroke()
    outerGlow.stroke()

    let innerGlow = NSBezierPath(roundedRect: bounds.insetBy(dx: size * 0.18, dy: size * 0.18), xRadius: radius * 0.58, yRadius: radius * 0.58)
    innerGlow.lineWidth = max(1.5, size * 0.012)
    NSColor.systemRed.withAlphaComponent(0.20).setStroke()
    innerGlow.stroke()

    let body = NSRect(x: size * 0.23, y: size * 0.39, width: size * 0.48, height: size * 0.23)
    let bodyPath = NSBezierPath(roundedRect: body, xRadius: size * 0.052, yRadius: size * 0.052)
    bodyPath.lineWidth = max(2, size * 0.034)
    NSColor.systemRed.setStroke()
    bodyPath.stroke()

    let nub = NSBezierPath(
        roundedRect: NSRect(x: body.maxX + size * 0.035, y: body.midY - size * 0.05, width: size * 0.052, height: size * 0.10),
        xRadius: size * 0.018,
        yRadius: size * 0.018
    )
    NSColor.systemRed.setFill()
    nub.fill()

    let lowFill = NSBezierPath(
        roundedRect: NSRect(x: body.minX + size * 0.055, y: body.minY + size * 0.055, width: size * 0.12, height: body.height - size * 0.11),
        xRadius: size * 0.018,
        yRadius: size * 0.018
    )
    NSColor.systemRed.withAlphaComponent(0.76).setFill()
    lowFill.fill()

    image.unlockFocus()
    return image
}
