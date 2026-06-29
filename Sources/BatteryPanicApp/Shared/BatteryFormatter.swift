import Foundation

enum BatteryFormatter {
    static let pendingMenuTitle = "--%"

    static func menuTitle(for status: BatteryStatus, threshold: Int) -> String {
        guard status.hasBattery else { return pendingMenuTitle }
        if status.isPluggedIn {
            return "\(status.percentage)%"
        }
        if status.percentage <= threshold {
            return "\(status.percentage)%"
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
}
