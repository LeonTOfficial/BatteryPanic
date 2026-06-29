import AppKit
import CoreGraphics

final class OverlayWindow: NSWindow {
    var overlayView: OverlayView {
        guard let overlayView = contentView as? OverlayView else {
            preconditionFailure("OverlayWindow contentView must be OverlayView")
        }
        return overlayView
    }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        commonInit()
    }

    convenience init(screen: NSScreen) {
        self.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        let overlayView = OverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        overlayView.autoresizingMask = [.width, .height]
        self.contentView = overlayView
    }

    private func commonInit() {
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
    }
}
