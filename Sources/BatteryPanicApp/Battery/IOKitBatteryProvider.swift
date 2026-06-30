import Foundation
import IOKit.ps

final class IOKitBatteryProvider: BatteryProviding {
    func currentStatus() -> BatteryStatus {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(info).takeRetainedValue() as NSArray

        guard sources.count > 0 else {
            return BatteryStatus.noBattery()
        }

        for source in sources {
            guard
                let description = IOPSGetPowerSourceDescription(
                    info,
                    source as CFTypeRef
                )?.takeUnretainedValue() as? [String: Any]
            else {
                continue
            }

            guard let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int else {
                continue
            }

            let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
            let percentage = Self.percentage(current: currentCapacity, max: maxCapacity)
            let stateValue = description[kIOPSPowerSourceStateKey] as? String
            let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
            let timeRemaining = Self.timeRemainingMinutes(from: description, isCharging: isCharging)

            return BatteryStatus(
                percentage: percentage,
                powerSource: Self.powerSource(from: stateValue),
                isCharging: isCharging,
                hasBattery: true,
                timeRemainingMinutes: timeRemaining
            )
        }

        return BatteryStatus.noBattery()
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

    private static func timeRemainingMinutes(from description: [String: Any], isCharging: Bool) -> Int? {
        let key = isCharging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
        guard let minutes = description[key] as? Int, minutes > 0 else {
            return nil
        }
        return minutes
    }
}
