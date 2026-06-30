import Foundation

enum PowerSource: String, Equatable {
    case batteryPower
    case acPower
    case unknown
}

struct BatteryStatus: Equatable {
    let percentage: Int
    let powerSource: PowerSource
    let isCharging: Bool
    let hasBattery: Bool
    let timeRemainingMinutes: Int?
    let timestamp: Date

    init(
        percentage: Int,
        powerSource: PowerSource,
        isCharging: Bool,
        hasBattery: Bool,
        timeRemainingMinutes: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.percentage = percentage.clamped(to: 0...100)
        self.powerSource = powerSource
        self.isCharging = isCharging
        self.hasBattery = hasBattery
        self.timeRemainingMinutes = timeRemainingMinutes
        self.timestamp = timestamp
    }

    var isPluggedIn: Bool {
        powerSource == .acPower || isCharging
    }

    static func noBattery() -> BatteryStatus {
        BatteryStatus(
            percentage: 100,
            powerSource: .unknown,
            isCharging: false,
            hasBattery: false
        )
    }
}
