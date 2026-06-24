import AppKit

enum BatteryStatusLevel: Equatable {
    case healthy
    case warning
    case critical
    case charging
    case unavailable
}

struct BatteryStatusAppearance {
    let level: BatteryStatusLevel
    let color: NSColor
    let title: String
    let subtitle: String
    let showsBolt: Bool
    let showsCriticalDot: Bool

    static func appearance(for status: BatteryStatus, threshold: Int) -> BatteryStatusAppearance {
        guard status.hasBattery else {
            return BatteryStatusAppearance(
                level: .unavailable,
                color: .secondaryLabelColor,
                title: "No battery",
                subtitle: "Battery status is not available.",
                showsBolt: false,
                showsCriticalDot: false
            )
        }

        if status.isPluggedIn {
            return BatteryStatusAppearance(
                level: .charging,
                color: .systemGreen,
                title: "\(status.percentage)% charging",
                subtitle: "Power adapter connected.",
                showsBolt: true,
                showsCriticalDot: false
            )
        }

        let warningThreshold = max(threshold + 8, min(35, threshold * 2))
        if status.percentage <= threshold {
            return BatteryStatusAppearance(
                level: .critical,
                color: .systemRed,
                title: "\(status.percentage)% critical",
                subtitle: "Plug in your charger to recover.",
                showsBolt: false,
                showsCriticalDot: true
            )
        }

        if status.percentage <= warningThreshold {
            return BatteryStatusAppearance(
                level: .warning,
                color: .systemOrange,
                title: "\(status.percentage)% getting low",
                subtitle: "Battery is approaching your warning level.",
                showsBolt: false,
                showsCriticalDot: false
            )
        }

        return BatteryStatusAppearance(
            level: .healthy,
            color: .systemGreen,
            title: "\(status.percentage)% battery",
            subtitle: "Battery level is healthy.",
            showsBolt: false,
            showsCriticalDot: false
        )
    }
}
