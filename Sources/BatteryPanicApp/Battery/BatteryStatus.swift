import Foundation

enum PowerSource: String, Equatable {
    case batteryPower
    case acPower
    case unknown
}

enum BatteryPowerState: Equatable {
    case onBattery
    case charging
    case connectedNotCharging
    case unknown
}

enum BatteryHealth: Equatable {
    case good
    case fair
    case poor
    case unknown(String)

    var displayName: String {
        switch self {
        case .good:
            return "Good"
        case .fair:
            return "Fair"
        case .poor:
            return "Poor"
        case .unknown(let value):
            return value
        }
    }
}

enum BatteryHealthCondition: Equatable {
    case checkBattery
    case permanentFailure
    case unknown(String)

    var displayName: String {
        switch self {
        case .checkBattery:
            return "Check Battery"
        case .permanentFailure:
            return "Permanent Battery Failure"
        case .unknown(let value):
            return value
        }
    }
}

struct BatteryStatus: Equatable {
    let percentage: Int
    let powerSource: PowerSource
    let isCharging: Bool
    let isCharged: Bool
    let isFinishingCharge: Bool
    let hasBattery: Bool
    let health: BatteryHealth?
    let healthCondition: BatteryHealthCondition?
    let timeRemainingMinutes: Int?
    let timestamp: Date

    init(
        percentage: Int,
        powerSource: PowerSource,
        isCharging: Bool,
        isCharged: Bool = false,
        isFinishingCharge: Bool = false,
        hasBattery: Bool,
        health: BatteryHealth? = nil,
        healthCondition: BatteryHealthCondition? = nil,
        timeRemainingMinutes: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.percentage = percentage.clamped(to: 0...100)
        self.powerSource = powerSource
        self.isCharging = isCharging
        self.isCharged = isCharged
        self.isFinishingCharge = isFinishingCharge
        self.hasBattery = hasBattery
        self.health = health
        self.healthCondition = healthCondition
        self.timeRemainingMinutes = timeRemainingMinutes
        self.timestamp = timestamp
    }

    var powerState: BatteryPowerState {
        if isActivelyCharging {
            return .charging
        }

        switch powerSource {
        case .batteryPower:
            return .onBattery
        case .acPower:
            return .connectedNotCharging
        case .unknown:
            return .unknown
        }
    }

    var isPluggedIn: Bool {
        powerState == .charging || powerState == .connectedNotCharging
    }

    /// IOKit can report the final top-off phase separately from its primary
    /// charging flag. Both states mean the battery is still receiving charge.
    var isActivelyCharging: Bool {
        isCharging || isFinishingCharge
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
