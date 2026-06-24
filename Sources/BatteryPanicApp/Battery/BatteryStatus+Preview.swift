import Foundation

extension BatteryStatus {
    static func lowBatteryPreview(threshold: Int) -> BatteryStatus {
        let previewPercentage = max(1, min(threshold - 1, AppConstants.defaultThreshold))
        return BatteryStatus(
            percentage: previewPercentage,
            powerSource: .batteryPower,
            isCharging: false,
            hasBattery: true
        )
    }
}
