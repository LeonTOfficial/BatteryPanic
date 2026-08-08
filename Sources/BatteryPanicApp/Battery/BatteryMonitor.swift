import Foundation

final class BatteryMonitor {
    private let provider: BatteryProviding
    private let interval: TimeInterval
    private let workerQueue: DispatchQueue
    private var timer: Timer?
    private var generation = 0
    private var isRunning = false
    private var isRequestInFlight = false
    private var refreshPending = false

    var onStatusUpdate: ((BatteryStatus) -> Void)?

    init(
        provider: BatteryProviding = IOKitBatteryProvider(),
        interval: TimeInterval = AppConstants.pollInterval,
        workerQueue: DispatchQueue = DispatchQueue(label: "com.leontofficial.batterypanic.battery-monitor", qos: .utility)
    ) {
        self.provider = provider
        self.interval = interval
        self.workerQueue = workerQueue
    }

    func start() {
        stop()
        isRunning = true
        generation += 1
        requestStatus()

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.requestStatus()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        generation += 1
        refreshPending = false
    }

    func refresh() {
        requestStatus()
    }

    private func requestStatus() {
        guard isRunning else { return }
        guard !isRequestInFlight else {
            refreshPending = true
            return
        }

        isRequestInFlight = true
        let requestGeneration = generation
        workerQueue.async { [weak self] in
            guard let self else { return }
            let status = provider.currentStatus()
            DispatchQueue.main.async { [weak self] in
                self?.finishRequest(status, generation: requestGeneration)
            }
        }
    }

    private func finishRequest(_ status: BatteryStatus, generation requestGeneration: Int) {
        isRequestInFlight = false

        if isRunning, requestGeneration == generation {
            onStatusUpdate?(status)
        }

        let shouldRefresh = isRunning && (refreshPending || requestGeneration != generation)
        refreshPending = false
        if shouldRefresh {
            requestStatus()
        }
    }
}
