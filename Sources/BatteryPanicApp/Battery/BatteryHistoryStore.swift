import Foundation

struct BatteryHistorySample: Codable, Equatable {
    let timestamp: Date
    let percentage: Int
    let powerSource: PowerSource
    let isCharging: Bool

    init(
        timestamp: Date,
        percentage: Int,
        powerSource: PowerSource,
        isCharging: Bool
    ) {
        self.timestamp = timestamp
        self.percentage = percentage.clamped(to: 0...100)
        self.powerSource = powerSource
        self.isCharging = isCharging
    }

    init?(status: BatteryStatus) {
        guard status.hasBattery else { return nil }
        self.init(
            timestamp: status.timestamp,
            percentage: status.percentage,
            powerSource: status.powerSource,
            isCharging: status.isActivelyCharging
        )
    }

    private enum CodingKeys: String, CodingKey {
        case timestamp
        case percentage
        case powerSource
        case isCharging
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let percentage = try container.decode(Int.self, forKey: .percentage)
        let rawPowerSource = try container.decode(String.self, forKey: .powerSource)
        let isCharging = try container.decode(Bool.self, forKey: .isCharging)
        self.init(
            timestamp: timestamp,
            percentage: percentage,
            powerSource: PowerSource(rawValue: rawPowerSource) ?? .unknown,
            isCharging: isCharging
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(percentage, forKey: .percentage)
        try container.encode(powerSource.rawValue, forKey: .powerSource)
        try container.encode(isCharging, forKey: .isCharging)
    }
}

enum BatteryHistoryRange: CaseIterable, Hashable {
    case thirtyMinutes
    case oneHour
    case oneDay
    case sevenDays

    var duration: TimeInterval {
        switch self {
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        case .oneDay:
            return 24 * 60 * 60
        case .sevenDays:
            return 7 * 24 * 60 * 60
        }
    }
}

enum BatteryForecastHorizon: CaseIterable, Equatable {
    case thirtyMinutes
    case oneHour
    case oneDay

    var duration: TimeInterval {
        switch self {
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        case .oneDay:
            return 24 * 60 * 60
        }
    }
}

struct BatteryHistoryForecast: Equatable {
    let horizon: BatteryForecastHorizon
    let currentPercentage: Int
    let projectedPercentage: Double
    let projectedChange: Double
    let ratePercentagePerHour: Double
    let powerSource: PowerSource
    let isCharging: Bool
}

struct BatteryHistoryPowerPhase: Equatable {
    let start: Date
    let end: Date
    let powerSource: PowerSource
    let isCharging: Bool
}

final class BatteryHistoryStore {
    static let maximumRetentionDuration: TimeInterval = 7 * 24 * 60 * 60
    static let minimumSamplingInterval: TimeInterval = 60

    private static let persistedSchemaVersion = 1
    private static let maximumTrendPointCount = 120
    private static let minimumTrendSampleCount = 3
    private static let minimumTrendPhaseDuration: TimeInterval = 10 * 60

    private struct PersistedHistory: Codable {
        let schemaVersion: Int
        let samples: [BatteryHistorySample]
    }

    private struct PowerPhaseIdentity: Equatable {
        let powerSource: PowerSource
        let isCharging: Bool
    }

    private let storageURL: URL?
    private let retentionDuration: TimeInterval
    private let flushInterval: TimeInterval
    private let nowProvider: () -> Date
    private let fileManager: FileManager
    private let persistenceQueue: DispatchQueue
    private let lock = NSLock()
    private let persistenceWriteLock = NSLock()

    private var samples: [BatteryHistorySample]
    private var scheduledFlush: DispatchWorkItem?
    private var mutationVersion = 0
    private var isDirty = false
    private var isStopped = false

    /// Called on the persistence queue if a scheduled JSON write fails.
    var onPersistenceError: ((Error) -> Void)?

    init(
        storageURL: URL? = BatteryHistoryStore.defaultStorageURL(),
        retentionDuration: TimeInterval = BatteryHistoryStore.maximumRetentionDuration,
        flushInterval: TimeInterval = 2 * 60,
        now: @escaping () -> Date = Date.init,
        fileManager: FileManager = .default,
        persistenceQueue: DispatchQueue = DispatchQueue(
            label: "com.leontofficial.batterypanic.battery-history",
            qos: .utility
        )
    ) {
        self.storageURL = storageURL
        self.retentionDuration = max(0, min(retentionDuration, Self.maximumRetentionDuration))
        self.flushInterval = max(0, flushInterval)
        self.nowProvider = now
        self.fileManager = fileManager
        self.persistenceQueue = persistenceQueue

        let loadedSamples = storageURL.flatMap(Self.loadSamples(from:)) ?? []
        self.samples = Self.normalized(
            loadedSamples,
            cutoff: now().addingTimeInterval(-self.retentionDuration)
        )
    }

    static func defaultStorageURL(fileManager: FileManager = .default) -> URL? {
        let bundleIdentifier = Bundle.main.bundleIdentifier
            ?? "com.leontofficial.batterypanic.mac"
        return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("battery-history.json", isDirectory: false)
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return samples.count
    }

    var latestSample: BatteryHistorySample? {
        lock.lock()
        defer { lock.unlock() }
        return samples.last
    }

    @discardableResult
    func record(_ status: BatteryStatus) -> Bool {
        guard let sample = BatteryHistorySample(status: status) else { return false }
        return record(sample)
    }

    /// Records one normal observation for a UTC minute bucket, while retaining
    /// additional observations that mark a power-source or charging transition.
    ///
    /// Repeated steady-state updates replace the normal value for that minute.
    /// This keeps the buffer compact without hiding a plug/unplug event that
    /// happens between two regular minute samples.
    @discardableResult
    func record(_ sample: BatteryHistorySample) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard !isStopped else { return false }

        let cutoff = nowProvider().addingTimeInterval(-retentionDuration)
        let firstRetainedIndex = Self.lowerBound(in: samples, timestamp: cutoff)
        if firstRetainedIndex > 0 {
            samples.removeFirst(firstRetainedIndex)
            markDirtyAndScheduleFlushLocked()
        }

        guard sample.timestamp >= cutoff else { return false }

        let minuteStartInterval = floor(
            sample.timestamp.timeIntervalSince1970 / Self.minimumSamplingInterval
        ) * Self.minimumSamplingInterval
        let minuteStart = Date(timeIntervalSince1970: minuteStartInterval)
        let nextMinute = minuteStart.addingTimeInterval(Self.minimumSamplingInterval)
        let bucketStartIndex = Self.lowerBound(in: samples, timestamp: minuteStart)
        let bucketEndIndex = Self.lowerBound(in: samples, timestamp: nextMinute)

        let existingBucket = Array(samples[bucketStartIndex..<bucketEndIndex])
        let previousSample = bucketStartIndex > 0 ? samples[bucketStartIndex - 1] : nil
        let updatedBucket = Self.canonicalBucketSamples(
            existingBucket + [sample],
            previousSample: previousSample
        )
        guard existingBucket != updatedBucket else { return false }
        samples.replaceSubrange(bucketStartIndex..<bucketEndIndex, with: updatedBucket)

        markDirtyAndScheduleFlushLocked()
        return true
    }

    func allSamples() -> [BatteryHistorySample] {
        lock.lock()
        defer { lock.unlock() }
        return samples
    }

    func samples(
        in range: BatteryHistoryRange,
        endingAt endDate: Date = Date()
    ) -> [BatteryHistorySample] {
        let snapshot = allSamples()
        let startDate = endDate.addingTimeInterval(-range.duration)
        let startIndex = Self.lowerBound(in: snapshot, timestamp: startDate)
        let endIndex = Self.upperBound(in: snapshot, timestamp: endDate)
        guard startIndex < endIndex else { return [] }
        return Array(snapshot[startIndex..<endIndex])
    }

    func downsampledSamples(
        in range: BatteryHistoryRange,
        endingAt endDate: Date = Date(),
        maximumCount: Int
    ) -> [BatteryHistorySample] {
        let rangeSamples = samples(in: range, endingAt: endDate)
        return Self.largestTriangleThreeBuckets(rangeSamples, maximumCount: maximumCount)
    }

    /// Returns signed observed change (`last - first`) within the selected range.
    func actualPercentageChange(
        in range: BatteryHistoryRange,
        endingAt endDate: Date = Date()
    ) -> Int? {
        let rangeSamples = samples(in: range, endingAt: endDate)
        guard let first = rangeSamples.first, let last = rangeSamples.last, first != last else {
            return nil
        }
        return last.percentage - first.percentage
    }

    /// Groups consecutive observations so charging and power-source periods can
    /// be drawn independently from the downsampled percentage line.
    func powerPhases(
        in range: BatteryHistoryRange,
        endingAt endDate: Date = Date()
    ) -> [BatteryHistoryPowerPhase] {
        let rangeSamples = samples(in: range, endingAt: endDate)
        guard let first = rangeSamples.first else { return [] }

        var phases: [BatteryHistoryPowerPhase] = []
        var phaseStart = first.timestamp
        var identity = PowerPhaseIdentity(
            powerSource: first.powerSource,
            isCharging: first.isCharging
        )

        for sample in rangeSamples.dropFirst() {
            let sampleIdentity = PowerPhaseIdentity(
                powerSource: sample.powerSource,
                isCharging: sample.isCharging
            )
            guard sampleIdentity != identity else { continue }

            phases.append(
                BatteryHistoryPowerPhase(
                    start: phaseStart,
                    end: sample.timestamp,
                    powerSource: identity.powerSource,
                    isCharging: identity.isCharging
                )
            )
            phaseStart = sample.timestamp
            identity = sampleIdentity
        }

        let lastKnownEnd = min(
            endDate,
            rangeSamples.last!.timestamp.addingTimeInterval(Self.minimumSamplingInterval)
        )
        phases.append(
            BatteryHistoryPowerPhase(
                start: phaseStart,
                end: lastKnownEnd,
                powerSource: identity.powerSource,
                isCharging: identity.isCharging
            )
        )
        return phases
    }

    /// Theil-Sen slope for the latest uninterrupted power phase, in percentage
    /// points per hour. This resists individual percentage outliers and avoids
    /// mixing an earlier charging period into the current discharge estimate.
    func trendRatePercentagePerHour(
        in range: BatteryHistoryRange,
        endingAt endDate: Date = Date()
    ) -> Double? {
        let rangeSamples = samples(in: range, endingAt: endDate)
        return Self.robustTrendRate(for: Self.latestPowerPhaseSamples(in: rangeSamples))
    }

    func forecast(
        for horizon: BatteryForecastHorizon,
        basedOn range: BatteryHistoryRange = .oneHour,
        endingAt endDate: Date = Date()
    ) -> BatteryHistoryForecast? {
        let rangeSamples = samples(in: range, endingAt: endDate)
        let phaseSamples = Self.latestPowerPhaseSamples(in: rangeSamples)
        guard
            let latest = phaseSamples.last,
            let rate = Self.robustTrendRate(for: phaseSamples)
        else {
            return nil
        }

        if latest.isCharging {
            guard rate > 0 else { return nil }
        } else {
            guard latest.powerSource == .batteryPower, rate < 0 else { return nil }
        }

        let projectedChange = rate * horizon.duration / 3_600
        let projectedPercentage = (
            Double(latest.percentage) + projectedChange
        ).clamped(to: 0...100)
        return BatteryHistoryForecast(
            horizon: horizon,
            currentPercentage: latest.percentage,
            projectedPercentage: projectedPercentage,
            projectedChange: projectedPercentage - Double(latest.percentage),
            ratePercentagePerHour: rate,
            powerSource: latest.powerSource,
            isCharging: latest.isCharging
        )
    }

    func shortForecasts(
        basedOn range: BatteryHistoryRange = .oneHour,
        endingAt endDate: Date = Date()
    ) -> [BatteryHistoryForecast] {
        [BatteryForecastHorizon.thirtyMinutes, .oneHour].compactMap {
            forecast(for: $0, basedOn: range, endingAt: endDate)
        }
    }

    /// Writes the latest snapshot immediately. Normal recording uses a single
    /// delayed work item, which batches frequent monitor updates into one write.
    func flush() throws {
        guard let storageURL else { return }
        persistenceWriteLock.lock()
        defer { persistenceWriteLock.unlock() }

        let snapshot: [BatteryHistorySample]
        let version: Int
        lock.lock()
        guard isDirty else {
            lock.unlock()
            return
        }
        snapshot = samples
        version = mutationVersion
        lock.unlock()

        let persisted = PersistedHistory(
            schemaVersion: Self.persistedSchemaVersion,
            samples: snapshot
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(persisted)
        try fileManager.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: storageURL, options: .atomic)

        lock.lock()
        if mutationVersion == version {
            isDirty = false
        } else {
            scheduleFlushLocked()
        }
        lock.unlock()
    }

    /// Stops accepting samples and synchronously persists every pending change.
    func stop() throws {
        lock.lock()
        isStopped = true
        scheduledFlush?.cancel()
        scheduledFlush = nil
        lock.unlock()
        try flush()
    }

    private func markDirtyAndScheduleFlushLocked() {
        mutationVersion += 1
        isDirty = true
        scheduleFlushLocked()
    }

    private func scheduleFlushLocked() {
        guard storageURL != nil, scheduledFlush == nil, !isStopped else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.performScheduledFlush()
        }
        scheduledFlush = workItem
        persistenceQueue.asyncAfter(
            deadline: .now() + flushInterval,
            execute: workItem
        )
    }

    private func performScheduledFlush() {
        lock.lock()
        scheduledFlush = nil
        lock.unlock()

        do {
            try flush()
        } catch {
            onPersistenceError?(error)
            lock.lock()
            scheduleFlushLocked()
            lock.unlock()
        }
    }

    private static func loadSamples(from url: URL) -> [BatteryHistorySample]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        if let persisted = try? decoder.decode(PersistedHistory.self, from: data) {
            return persisted.samples
        }
        return try? decoder.decode([BatteryHistorySample].self, from: data)
    }

    private static func normalized(
        _ input: [BatteryHistorySample],
        cutoff: Date
    ) -> [BatteryHistorySample] {
        let sortedSamples = sortedAndDeduplicated(
            input.filter { $0.timestamp >= cutoff }
        )
        var normalizedSamples: [BatteryHistorySample] = []
        normalizedSamples.reserveCapacity(sortedSamples.count)

        var bucketStartIndex = 0
        while bucketStartIndex < sortedSamples.count {
            let bucket = minuteBucket(for: sortedSamples[bucketStartIndex].timestamp)
            var bucketEndIndex = bucketStartIndex + 1
            while
                bucketEndIndex < sortedSamples.count,
                minuteBucket(for: sortedSamples[bucketEndIndex].timestamp) == bucket
            {
                bucketEndIndex += 1
            }
            normalizedSamples.append(
                contentsOf: canonicalBucketSamples(
                    Array(sortedSamples[bucketStartIndex..<bucketEndIndex]),
                    previousSample: normalizedSamples.last
                )
            )
            bucketStartIndex = bucketEndIndex
        }
        return normalizedSamples
    }

    /// Keeps every observed state edge plus the latest non-edge observation in
    /// a bucket. The latter is the bucket's sole regular sample.
    private static func canonicalBucketSamples(
        _ input: [BatteryHistorySample],
        previousSample: BatteryHistorySample?
    ) -> [BatteryHistorySample] {
        let sortedSamples = sortedAndDeduplicated(input)
        var transitions: [BatteryHistorySample] = []
        var latestNormalSample: BatteryHistorySample?
        var previousIdentity = previousSample.map {
            PowerPhaseIdentity(powerSource: $0.powerSource, isCharging: $0.isCharging)
        }

        for sample in sortedSamples {
            let identity = PowerPhaseIdentity(
                powerSource: sample.powerSource,
                isCharging: sample.isCharging
            )
            if let previousIdentity, previousIdentity != identity {
                transitions.append(sample)
            } else {
                latestNormalSample = sample
            }
            previousIdentity = identity
        }

        if let latestNormalSample {
            transitions.append(latestNormalSample)
        }
        return sortedAndDeduplicated(transitions)
    }

    private static func sortedAndDeduplicated(
        _ input: [BatteryHistorySample]
    ) -> [BatteryHistorySample] {
        let sortedSamples = input.enumerated().sorted { left, right in
            if left.element.timestamp == right.element.timestamp {
                return left.offset < right.offset
            }
            return left.element.timestamp < right.element.timestamp
        }
        var result: [BatteryHistorySample] = []
        result.reserveCapacity(sortedSamples.count)
        for entry in sortedSamples {
            if result.last?.timestamp == entry.element.timestamp {
                result[result.count - 1] = entry.element
            } else {
                result.append(entry.element)
            }
        }
        return result
    }

    private static func minuteBucket(for date: Date) -> Int64 {
        Int64(floor(date.timeIntervalSince1970 / minimumSamplingInterval))
    }

    private static func lowerBound(
        in samples: [BatteryHistorySample],
        timestamp: Date
    ) -> Int {
        var lower = 0
        var upper = samples.count
        while lower < upper {
            let middle = (lower + upper) / 2
            if samples[middle].timestamp < timestamp {
                lower = middle + 1
            } else {
                upper = middle
            }
        }
        return lower
    }

    private static func upperBound(
        in samples: [BatteryHistorySample],
        timestamp: Date
    ) -> Int {
        var lower = 0
        var upper = samples.count
        while lower < upper {
            let middle = (lower + upper) / 2
            if samples[middle].timestamp <= timestamp {
                lower = middle + 1
            } else {
                upper = middle
            }
        }
        return lower
    }

    private static func latestPowerPhaseSamples(
        in samples: [BatteryHistorySample]
    ) -> [BatteryHistorySample] {
        guard let latest = samples.last else { return [] }
        let identity = PowerPhaseIdentity(
            powerSource: latest.powerSource,
            isCharging: latest.isCharging
        )
        var startIndex = samples.count - 1
        while startIndex > 0 {
            let previous = samples[startIndex - 1]
            let previousIdentity = PowerPhaseIdentity(
                powerSource: previous.powerSource,
                isCharging: previous.isCharging
            )
            guard previousIdentity == identity else { break }
            startIndex -= 1
        }
        return Array(samples[startIndex...])
    }

    private static func robustTrendRate(
        for samples: [BatteryHistorySample]
    ) -> Double? {
        guard
            samples.count >= minimumTrendSampleCount,
            let first = samples.first,
            let last = samples.last,
            last.timestamp.timeIntervalSince(first.timestamp) >= minimumTrendPhaseDuration
        else {
            return nil
        }
        let trendSamples = evenlySpaced(samples, maximumCount: maximumTrendPointCount)
        var slopes: [Double] = []
        slopes.reserveCapacity(trendSamples.count * (trendSamples.count - 1) / 2)

        for firstIndex in 0..<(trendSamples.count - 1) {
            let first = trendSamples[firstIndex]
            for secondIndex in (firstIndex + 1)..<trendSamples.count {
                let second = trendSamples[secondIndex]
                let elapsed = second.timestamp.timeIntervalSince(first.timestamp)
                guard elapsed >= minimumSamplingInterval else { continue }
                let percentageChange = Double(second.percentage - first.percentage)
                slopes.append(percentageChange / elapsed * 3_600)
            }
        }

        guard !slopes.isEmpty else { return nil }
        slopes.sort()
        let middle = slopes.count / 2
        if slopes.count.isMultiple(of: 2) {
            return (slopes[middle - 1] + slopes[middle]) / 2
        }
        return slopes[middle]
    }

    private static func evenlySpaced(
        _ samples: [BatteryHistorySample],
        maximumCount: Int
    ) -> [BatteryHistorySample] {
        guard samples.count > maximumCount, maximumCount >= 2 else { return samples }
        let scale = Double(samples.count - 1) / Double(maximumCount - 1)
        return (0..<maximumCount).map { index in
            samples[Int((Double(index) * scale).rounded())]
        }
    }

    private static func largestTriangleThreeBuckets(
        _ samples: [BatteryHistorySample],
        maximumCount: Int
    ) -> [BatteryHistorySample] {
        guard maximumCount > 0, !samples.isEmpty else { return [] }
        guard samples.count > maximumCount else { return samples }
        if maximumCount == 1 { return [samples.last!] }
        if maximumCount == 2 { return [samples.first!, samples.last!] }

        let bucketWidth = Double(samples.count - 2) / Double(maximumCount - 2)
        var result: [BatteryHistorySample] = [samples[0]]
        result.reserveCapacity(maximumCount)
        var selectedIndex = 0

        for bucket in 0..<(maximumCount - 2) {
            let averageStart = min(
                samples.count,
                Int(floor(Double(bucket + 1) * bucketWidth)) + 1
            )
            let averageEnd = min(
                samples.count,
                Int(floor(Double(bucket + 2) * bucketWidth)) + 1
            )
            let averageRange = averageStart..<max(averageStart + 1, averageEnd)
            let boundedAverageRange = averageRange.clamped(to: 0..<samples.count)
            let averageTimestamp = boundedAverageRange.reduce(0.0) {
                $0 + samples[$1].timestamp.timeIntervalSince1970
            } / Double(boundedAverageRange.count)
            let averagePercentage = boundedAverageRange.reduce(0.0) {
                $0 + Double(samples[$1].percentage)
            } / Double(boundedAverageRange.count)

            let candidateStart = min(
                samples.count - 1,
                Int(floor(Double(bucket) * bucketWidth)) + 1
            )
            let candidateEnd = min(
                samples.count - 1,
                Int(floor(Double(bucket + 1) * bucketWidth)) + 1
            )
            let anchor = samples[selectedIndex]
            var maximumArea = -Double.infinity
            var nextSelectedIndex = candidateStart

            for candidateIndex in candidateStart..<max(candidateStart + 1, candidateEnd) {
                let candidate = samples[candidateIndex]
                let area = abs(
                    (anchor.timestamp.timeIntervalSince1970 - averageTimestamp)
                        * (Double(candidate.percentage) - Double(anchor.percentage))
                        - (anchor.timestamp.timeIntervalSince1970
                            - candidate.timestamp.timeIntervalSince1970)
                        * (averagePercentage - Double(anchor.percentage))
                )
                if area > maximumArea {
                    maximumArea = area
                    nextSelectedIndex = candidateIndex
                }
            }

            result.append(samples[nextSelectedIndex])
            selectedIndex = nextSelectedIndex
        }

        result.append(samples.last!)
        return result
    }
}

private extension Range where Bound == Int {
    func clamped(to limits: Range<Int>) -> Range<Int> {
        Swift.max(lowerBound, limits.lowerBound)..<Swift.min(upperBound, limits.upperBound)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
