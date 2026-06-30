import Foundation

enum BatteryFormatter {
    static let pendingMenuTitle = "--%"

    static func menuTitle(for status: BatteryStatus, threshold: Int) -> String {
        guard status.hasBattery else { return pendingMenuTitle }
        if status.isPluggedIn {
            return "⚡ \(status.percentage)%"
        }
        if status.percentage <= threshold {
            return "! \(status.percentage)%"
        }
        return "\(status.percentage)%"
    }

    static func longStatus(for status: BatteryStatus) -> String {
        guard status.hasBattery else { return "No battery found" }

        let source: String
        switch status.powerSource {
        case .batteryPower:
            source = "battery"
        case .acPower:
            source = status.isCharging ? "charging" : "power adapter"
        case .unknown:
            source = "unknown power source"
        }

        return "\(status.percentage)% on \(source)"
    }

    static func timeRemainingText(for status: BatteryStatus) -> String? {
        guard let minutes = status.timeRemainingMinutes, minutes > 0 else {
            return nil
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        let value: String
        if hours > 0, remainingMinutes > 0 {
            value = "\(hours)h \(remainingMinutes)m"
        } else if hours > 0 {
            value = "\(hours)h"
        } else {
            value = "\(remainingMinutes)m"
        }

        return status.isCharging ? "About \(value) until full" : "About \(value) remaining"
    }
}
