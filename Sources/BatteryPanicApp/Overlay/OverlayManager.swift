import AppKit
import Foundation

enum OverlayAnimationPolicy {
    static func shouldAnimate(pulseEnabled: Bool, reduceMotion: Bool) -> Bool {
        pulseEnabled && !reduceMotion
    }
}

final class OverlayManager: NSObject {
    private var windows: [OverlayWindow] = []
    private var animationTimer: Timer?
    private var animationStart = Date()
    private var currentStatus: BatteryStatus?
    private var currentPulseEnabled = true
    private var currentPulseSpeed = 1.0
    private var currentPulseIntensity = 1.0
    private var currentIsTest = false
    private var currentDisplayMode = OverlayDisplayMode.lowBattery
    private let reduceMotionEnabled: () -> Bool

    init(reduceMotionEnabled: @escaping () -> Bool = {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }) {
        self.reduceMotionEnabled = reduceMotionEnabled
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(accessibilityDisplayOptionsChanged),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func show(
        status: BatteryStatus,
        pulseEnabled: Bool,
        pulseSpeed: Double,
        pulseIntensity: Double,
        displayMode: OverlayDisplayMode = .lowBattery,
        isTest: Bool
    ) {
        currentStatus = status
        currentPulseEnabled = pulseEnabled
        currentPulseSpeed = pulseSpeed.isFinite ? pulseSpeed.clamped(to: 0.4...2.4) : 1.0
        currentPulseIntensity = pulseIntensity.isFinite ? pulseIntensity.clamped(to: 0.45...1.6) : 1.0
        currentDisplayMode = displayMode
        currentIsTest = isTest

        if windows.count != NSScreen.screens.count {
            closeWindows()
            createWindows()
        }

        updateWindows()
        windows.forEach { window in
            window.orderFrontRegardless()
            window.contentView?.needsDisplay = true
        }
        startAnimation()
    }

    func hide() {
        stopAnimation()
        closeWindows()
    }

    private func closeWindows() {
        windows.forEach { window in
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
    }

    private func createWindows() {
        windows = NSScreen.screens.map { OverlayWindow(screen: $0) }
    }

    private func updateWindows() {
        guard let currentStatus else { return }
        zip(windows, NSScreen.screens).forEach { window, screen in
            let targetFrame = screen.frame
            window.setFrame(targetFrame, display: true)
            window.overlayView.frame = NSRect(origin: .zero, size: targetFrame.size)
            window.overlayView.percentage = currentStatus.percentage
            window.overlayView.timeRemainingText = BatteryFormatter.timeRemainingText(for: currentStatus)
            window.overlayView.pulseEnabled = shouldAnimatePulse
            if !shouldAnimatePulse {
                window.overlayView.pulseValue = 1
            }
            window.overlayView.pulseIntensity = CGFloat(currentPulseIntensity)
            window.overlayView.displayMode = currentDisplayMode
            window.overlayView.isTest = currentIsTest
            window.overlayView.needsDisplay = true
        }
    }

    private func startAnimation() {
        guard shouldAnimatePulse else {
            stopAnimation()
            windows.forEach { $0.overlayView.pulseValue = 1 }
            return
        }
        guard animationTimer == nil else { return }
        animationStart = Date()

        let timer = Timer(timeInterval: 1.0 / 24.0, repeats: true) { [weak self] _ in
            self?.tickAnimation()
        }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func tickAnimation() {
        guard shouldAnimatePulse else {
            stopAnimation()
            return
        }
        let elapsed = Date().timeIntervalSince(animationStart)
        let pulse = (sin(elapsed * 2.4 * currentPulseSpeed) + 1.0) / 2.0
        windows.forEach { window in
            window.overlayView.pulseValue = CGFloat(pulse)
        }
    }

    @objc private func screenParametersChanged() {
        guard !windows.isEmpty else { return }
        hide()
        if let currentStatus {
            show(
                status: currentStatus,
                pulseEnabled: currentPulseEnabled,
                pulseSpeed: currentPulseSpeed,
                pulseIntensity: currentPulseIntensity,
                displayMode: currentDisplayMode,
                isTest: currentIsTest
            )
        }
    }

    @objc private func accessibilityDisplayOptionsChanged() {
        guard !windows.isEmpty else { return }
        updateWindows()
        startAnimation()
    }

    private var shouldAnimatePulse: Bool {
        OverlayAnimationPolicy.shouldAnimate(
            pulseEnabled: currentPulseEnabled,
            reduceMotion: reduceMotionEnabled()
        )
    }
}
