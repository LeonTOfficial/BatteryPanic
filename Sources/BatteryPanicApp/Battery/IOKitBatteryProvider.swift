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

    private static func timeRemainingMinutes(from description: [String: Any], isCharging: Bool) -> Int? {
        let key = isCharging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
        guard let minutes = description[key] as? Int, minutes > 0 else {
            return nil
        }
        return minutes
    }
}
