import Foundation
import IOKit.ps

final class IOKitBatteryProvider: BatteryProviding {
    typealias DescriptionReader = () -> [[String: Any]]?

    private let readDescriptions: DescriptionReader

    init(readDescriptions: @escaping DescriptionReader = IOKitBatteryProvider.readPowerSourceDescriptions) {
        self.readDescriptions = readDescriptions
    }

    func currentStatus() -> BatteryStatus {
        guard let descriptions = readDescriptions(), !descriptions.isEmpty else {
            return BatteryStatus.noBattery()
        }

        for description in descriptions {
            guard let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int else {
                continue
            }

            let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
            let percentage = Self.percentage(current: currentCapacity, max: maxCapacity)
            let stateValue = description[kIOPSPowerSourceStateKey] as? String
            let powerSource = Self.powerSource(from: stateValue)
            let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
            let isFinishingCharge = description[kIOPSIsFinishingChargeKey] as? Bool ?? false
            let timeRemaining = Self.timeRemainingMinutes(
                from: description,
                powerSource: powerSource,
                isActivelyCharging: isCharging || isFinishingCharge
            )

            return BatteryStatus(
                percentage: percentage,
                powerSource: powerSource,
                isCharging: isCharging,
                isCharged: description[kIOPSIsChargedKey] as? Bool ?? false,
                isFinishingCharge: isFinishingCharge,
                hasBattery: true,
                health: Self.health(from: description[kIOPSBatteryHealthKey] as? String),
                healthCondition: Self.healthCondition(
                    from: description[kIOPSBatteryHealthConditionKey] as? String
                ),
                timeRemainingMinutes: timeRemaining
            )
        }

        return BatteryStatus.noBattery()
    }

    static func readPowerSourceDescriptions() -> [[String: Any]]? {
        guard let unmanagedInfo = IOPSCopyPowerSourcesInfo() else {
            return nil
        }
        let info = unmanagedInfo.takeRetainedValue()

        guard let unmanagedSources = IOPSCopyPowerSourcesList(info) else {
            return nil
        }
        let sources = unmanagedSources.takeRetainedValue() as NSArray

        return sources.compactMap { source in
            IOPSGetPowerSourceDescription(info, source as CFTypeRef)?
                .takeUnretainedValue() as? [String: Any]
        }
    }

    private static func percentage(current: Int, max: Int) -> Int {
        guard max > 0 else { return current.clamped(to: 0...100) }
        return Int(round((Double(current) / Double(max)) * 100.0)).clamped(to: 0...100)
    }

    private static func powerSource(from value: String?) -> PowerSource {
        switch value {
        case kIOPSACPowerValue:
            return .acPower
        case kIOPSBatteryPowerValue:
            return .batteryPower
        default:
            return .unknown
        }
    }

    private static func health(from value: String?) -> BatteryHealth? {
        guard let value = normalized(value) else { return nil }

        switch value {
        case kIOPSGoodValue:
            return .good
        case kIOPSFairValue:
            return .fair
        case kIOPSPoorValue:
            return .poor
        default:
            return .unknown(value)
        }
    }

    private static func healthCondition(from value: String?) -> BatteryHealthCondition? {
        guard let value = normalized(value) else { return nil }

        switch value {
        case kIOPSCheckBatteryValue:
            return .checkBattery
        case kIOPSPermanentFailureValue:
            return .permanentFailure
        default:
            return .unknown(value)
        }
    }

    private static func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private static func timeRemainingMinutes(
        from description: [String: Any],
        powerSource: PowerSource,
        isActivelyCharging: Bool
    ) -> Int? {
        let key: String
        if isActivelyCharging {
            key = kIOPSTimeToFullChargeKey
        } else if powerSource == .batteryPower {
            key = kIOPSTimeToEmptyKey
        } else {
            return nil
        }

        guard let minutes = description[key] as? Int, minutes > 0 else {
            return nil
        }
        return minutes
    }
}
