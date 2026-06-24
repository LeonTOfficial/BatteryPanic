import AppKit
import CoreGraphics

final class OverlayWindow: NSWindow {
    var overlayView: OverlayView {
        guard let overlayView = contentView as? OverlayView else {
            preconditionFailure("OverlayWindow contentView must be OverlayView")
        }
        return overlayView
    }

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        ignoresMouseEvents = true
        hasShadow = false
        isReleasedWhenClosed = false
        canHide = false
        animationBehavior = .none
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
            .stationary
        ]
        let overlayView = OverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        overlayView.autoresizingMask = [.width, .height]
        contentView = overlayView
    }
}
