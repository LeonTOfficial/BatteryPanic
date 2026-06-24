import Foundation

protocol BatteryProviding {
    func currentStatus() -> BatteryStatus
}
