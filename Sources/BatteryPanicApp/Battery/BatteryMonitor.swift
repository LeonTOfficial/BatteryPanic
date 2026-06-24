import Foundation

final class BatteryMonitor {
    private let provider: BatteryProviding
    private let interval: TimeInterval
    private var timer: Timer?

    var onStatusUpdate: ((BatteryStatus) -> Void)?

    init(provider: BatteryProviding = IOKitBatteryProvider(), interval: TimeInterval = AppConstants.pollInterval) {
        self.provider = provider
        self.interval = interval
    }

    func start() {
        stop()
        publishStatus()

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.publishStatus()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func publishStatus() {
        onStatusUpdate?(provider.currentStatus())
    }
}
