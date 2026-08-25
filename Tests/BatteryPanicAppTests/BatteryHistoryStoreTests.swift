import Foundation
import XCTest
@testable import BatteryPanicApp

final class BatteryHistoryStoreTests: XCTestCase {
    func testSampleCodableRoundTripPreservesPowerState() throws {
        let sample = BatteryHistorySample(
            timestamp: Date(timeIntervalSince1970: 1_700_000_123.456),
            percentage: 64,
            powerSource: .acPower,
            isCharging: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(sample)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        XCTAssertEqual(try decoder.decode(BatteryHistorySample.self, from: data), sample)
    }

    func testFinishingChargeStatusIsRecordedAsAChargingSample() throws {
        let status = BatteryStatus(
            percentage: 99,
            powerSource: .acPower,
            isCharging: false,
            isFinishingCharge: true,
            hasBattery: true,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let sample = try XCTUnwrap(BatteryHistorySample(status: status))

        XCTAssertTrue(sample.isCharging)
        XCTAssertEqual(sample.powerSource, .acPower)
    }

    func testSameMinuteKeepsOnlyNewestObservation() {
        let minuteStart = Date(timeIntervalSince1970: 1_700_000_000)
        let alignedStart = Date(
            timeIntervalSince1970: floor(minuteStart.timeIntervalSince1970 / 60) * 60
        )
        var now = alignedStart.addingTimeInterval(2 * 60)
        let store = makeStore(now: { now })

        XCTAssertTrue(store.record(sample(at: alignedStart.addingTimeInterval(5), percentage: 80)))
        XCTAssertTrue(store.record(sample(at: alignedStart.addingTimeInterval(50), percentage: 79)))
        XCTAssertFalse(store.record(sample(at: alignedStart.addingTimeInterval(20), percentage: 81)))
        XCTAssertTrue(store.record(sample(at: alignedStart.addingTimeInterval(65), percentage: 78)))

        let samples = store.allSamples()
        XCTAssertEqual(samples.map(\.percentage), [79, 78])
        XCTAssertEqual(samples.count, 2)
        now = alignedStart.addingTimeInterval(3 * 60)
    }

    func testPowerTransitionInsideMinuteIsKeptAlongsideOneNormalSample() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let minuteStart = Date(
            timeIntervalSince1970: floor(date.timeIntervalSince1970 / 60) * 60
        )
        let now = minuteStart.addingTimeInterval(2 * 60)
        let store = makeStore(now: { now })
        XCTAssertTrue(
            store.record(
                sample(
                    at: minuteStart.addingTimeInterval(-10),
                    percentage: 80,
                    powerSource: .batteryPower,
                    isCharging: false
                )
            )
        )
        XCTAssertTrue(
            store.record(
                sample(
                    at: minuteStart.addingTimeInterval(5),
                    percentage: 80,
                    powerSource: .batteryPower,
                    isCharging: false
                )
            )
        )
        XCTAssertTrue(
            store.record(
                sample(
                    at: minuteStart.addingTimeInterval(20),
                    percentage: 80,
                    powerSource: .acPower,
                    isCharging: true
                )
            )
        )
        XCTAssertTrue(
            store.record(
                sample(
                    at: minuteStart.addingTimeInterval(50),
                    percentage: 81,
                    powerSource: .acPower,
                    isCharging: true
                )
            )
        )

        let samplesInMinute = store.allSamples().filter {
            $0.timestamp >= minuteStart
                && $0.timestamp < minuteStart.addingTimeInterval(60)
        }
        XCTAssertEqual(samplesInMinute.count, 2)
        XCTAssertEqual(
            samplesInMinute.map(\.timestamp),
            [
                minuteStart.addingTimeInterval(20),
                minuteStart.addingTimeInterval(50)
            ]
        )
        XCTAssertTrue(samplesInMinute.allSatisfy(\.isCharging))

        let phases = store.powerPhases(in: .thirtyMinutes, endingAt: now)
        XCTAssertEqual(phases.count, 2)
        XCTAssertFalse(phases[0].isCharging)
        XCTAssertTrue(phases[1].isCharging)
        XCTAssertEqual(phases[1].start, minuteStart.addingTimeInterval(20))
    }

    func testRetentionNeverExceedsSevenDays() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        var now = base
        let store = makeStore(now: { now })
        XCTAssertTrue(store.record(sample(at: base.addingTimeInterval(-6 * 24 * 60 * 60), percentage: 90)))
        XCTAssertTrue(store.record(sample(at: base, percentage: 80)))

        now = base.addingTimeInterval(2 * 24 * 60 * 60)
        XCTAssertTrue(store.record(sample(at: now, percentage: 70)))

        XCTAssertEqual(store.allSamples().map(\.percentage), [80, 70])
        XCTAssertTrue(
            store.allSamples().allSatisfy {
                $0.timestamp >= now.addingTimeInterval(-BatteryHistoryStore.maximumRetentionDuration)
            }
        )
    }

    func testQueriesUseExactSupportedRanges() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let store = makeStore(now: { now })
        let observations: [(TimeInterval, Int)] = [
            (-6 * 24 * 60 * 60, 90),
            (-23 * 60 * 60, 80),
            (-50 * 60, 70),
            (-20 * 60, 60)
        ]
        observations.forEach {
            XCTAssertTrue(store.record(sample(at: now.addingTimeInterval($0.0), percentage: $0.1)))
        }

        XCTAssertEqual(store.samples(in: .thirtyMinutes, endingAt: now).map(\.percentage), [60])
        XCTAssertEqual(store.samples(in: .oneHour, endingAt: now).map(\.percentage), [70, 60])
        XCTAssertEqual(store.samples(in: .oneDay, endingAt: now).map(\.percentage), [80, 70, 60])
        XCTAssertEqual(store.samples(in: .sevenDays, endingAt: now).map(\.percentage), [90, 80, 70, 60])
    }

    func testDownsamplingPreservesEndpointsAndPointBudget() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(60 * 60)
        let store = makeStore(now: { end })
        for minute in 0...60 {
            XCTAssertTrue(
                store.record(
                    sample(
                        at: start.addingTimeInterval(Double(minute * 60)),
                        percentage: 100 - minute
                    )
                )
            )
        }

        let downsampled = store.downsampledSamples(
            in: .oneHour,
            endingAt: end,
            maximumCount: 12
        )

        XCTAssertEqual(downsampled.count, 12)
        XCTAssertEqual(downsampled.first?.percentage, 100)
        XCTAssertEqual(downsampled.last?.percentage, 40)
        XCTAssertEqual(downsampled.map(\.timestamp), downsampled.map(\.timestamp).sorted())
    }

    func testPowerPhasesAndTrendDoNotMixChargingWithDischarging() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(61 * 60)
        let store = makeStore(now: { end })
        let observations: [(Int, Int, PowerSource, Bool)] = [
            (0, 40, .batteryPower, false),
            (10, 39, .batteryPower, false),
            (20, 40, .acPower, true),
            (30, 50, .acPower, true),
            (40, 60, .acPower, true),
            (41, 60, .batteryPower, false),
            (51, 59, .batteryPower, false),
            (61, 58, .batteryPower, false)
        ]
        observations.forEach { minute, percentage, source, charging in
            XCTAssertTrue(
                store.record(
                    sample(
                        at: start.addingTimeInterval(Double(minute * 60)),
                        percentage: percentage,
                        powerSource: source,
                        isCharging: charging
                    )
                )
            )
        }

        let chargingEnd = start.addingTimeInterval(40 * 60)
        let chargingRate = try XCTUnwrap(
            store.trendRatePercentagePerHour(in: .oneHour, endingAt: chargingEnd)
        )
        XCTAssertEqual(chargingRate, 60, accuracy: 0.001)

        let phases = store.powerPhases(in: .oneHour, endingAt: end)
        XCTAssertEqual(phases.count, 3)
        XCTAssertFalse(phases[0].isCharging)
        XCTAssertTrue(phases[1].isCharging)
        XCTAssertEqual(phases[1].start, start.addingTimeInterval(20 * 60))
        XCTAssertEqual(phases[1].end, start.addingTimeInterval(41 * 60))
        XCTAssertFalse(phases[2].isCharging)

        let dischargingRate = try XCTUnwrap(
            store.trendRatePercentagePerHour(in: .oneHour, endingAt: end)
        )
        XCTAssertEqual(dischargingRate, -6, accuracy: 0.001)
    }

    func testRobustTrendAndShortForecastIgnoreSinglePercentageOutlier() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(30 * 60)
        let store = makeStore(now: { end })
        [100, 99, 50, 97].enumerated().forEach { index, percentage in
            XCTAssertTrue(
                store.record(
                    sample(
                        at: start.addingTimeInterval(Double(index * 10 * 60)),
                        percentage: percentage
                    )
                )
            )
        }

        let rate = try XCTUnwrap(
            store.trendRatePercentagePerHour(in: .oneHour, endingAt: end)
        )
        XCTAssertEqual(rate, -6, accuracy: 0.001)
        XCTAssertEqual(store.actualPercentageChange(in: .oneHour, endingAt: end), -3)

        let forecasts = store.shortForecasts(endingAt: end)
        XCTAssertEqual(forecasts.count, 2)
        XCTAssertEqual(forecasts[0].horizon, .thirtyMinutes)
        XCTAssertEqual(forecasts[0].projectedPercentage, 94, accuracy: 0.001)
        XCTAssertEqual(forecasts[1].horizon, .oneHour)
        XCTAssertEqual(forecasts[1].projectedPercentage, 91, accuracy: 0.001)
    }

    func testTrendAndForecastWaitForThreeSamplesAcrossTenMinutes() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var now = start.addingTimeInterval(60)
        let store = makeStore(now: { now })
        XCTAssertTrue(store.record(sample(at: start, percentage: 80)))
        XCTAssertTrue(store.record(sample(at: now, percentage: 79)))

        XCTAssertNil(store.trendRatePercentagePerHour(in: .oneHour, endingAt: now))
        XCTAssertTrue(store.shortForecasts(endingAt: now).isEmpty)

        now = start.addingTimeInterval(2 * 60)
        XCTAssertTrue(store.record(sample(at: now, percentage: 78)))
        XCTAssertNil(store.trendRatePercentagePerHour(in: .oneHour, endingAt: now))
        XCTAssertTrue(store.shortForecasts(endingAt: now).isEmpty)

        now = start.addingTimeInterval(10 * 60)
        XCTAssertTrue(store.record(sample(at: now, percentage: 70)))
        XCTAssertNotNil(store.trendRatePercentagePerHour(in: .oneHour, endingAt: now))
        XCTAssertEqual(store.shortForecasts(endingAt: now).count, 2)
    }

    func testOneDayForecastUsesOnlyTheLatestPhaseInsideTheDay() throws {
        let now = Date(timeIntervalSince1970: 1_700_086_400)
        let store = makeStore(now: { now })
        let observations: [(TimeInterval, Int, PowerSource, Bool)] = [
            (-23 * 60 * 60, 40, .acPower, true),
            (-22 * 60 * 60, 55, .acPower, true),
            (-60 * 60, 80, .batteryPower, false),
            (-30 * 60, 77, .batteryPower, false),
            (0, 74, .batteryPower, false)
        ]
        observations.forEach { offset, percentage, source, charging in
            XCTAssertTrue(
                store.record(
                    sample(
                        at: now.addingTimeInterval(offset),
                        percentage: percentage,
                        powerSource: source,
                        isCharging: charging
                    )
                )
            )
        }

        let forecast = try XCTUnwrap(
            store.forecast(for: .oneDay, basedOn: .oneDay, endingAt: now)
        )

        XCTAssertEqual(forecast.horizon, .oneDay)
        XCTAssertEqual(forecast.ratePercentagePerHour, -6, accuracy: 0.001)
        XCTAssertEqual(forecast.projectedPercentage, 0, accuracy: 0.001)
        XCTAssertFalse(forecast.isCharging)
    }

    func testStopFlushesAtomicallyPersistedJSONAndReloadsIt() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BatteryHistoryStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storageURL = directory.appendingPathComponent("history.json")
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let store = BatteryHistoryStore(
            storageURL: storageURL,
            flushInterval: 3_600,
            now: { now }
        )
        XCTAssertTrue(store.record(sample(at: now, percentage: 55, powerSource: .acPower, isCharging: true)))
        XCTAssertFalse(FileManager.default.fileExists(atPath: storageURL.path))

        try store.stop()

        XCTAssertTrue(FileManager.default.fileExists(atPath: storageURL.path))
        let reloaded = BatteryHistoryStore(storageURL: storageURL, now: { now })
        XCTAssertEqual(reloaded.allSamples(), store.allSamples())
        XCTAssertFalse(
            reloaded.record(
                sample(
                    at: now.addingTimeInterval(-10),
                    percentage: 54,
                    powerSource: .acPower,
                    isCharging: true
                )
            )
        )
    }

    func testPersistenceRoundTripKeepsMultipleSamplesAndSameMinutePowerTransition() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BatteryHistoryStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storageURL = directory.appendingPathComponent("history.json")
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let minuteStart = Date(
            timeIntervalSince1970: floor(date.timeIntervalSince1970 / 60) * 60
        )
        let now = minuteStart.addingTimeInterval(2 * 60)
        let store = BatteryHistoryStore(
            storageURL: storageURL,
            flushInterval: 3_600,
            now: { now }
        )
        let observations = [
            sample(
                at: minuteStart.addingTimeInterval(-10),
                percentage: 61,
                powerSource: .batteryPower,
                isCharging: false
            ),
            sample(
                at: minuteStart.addingTimeInterval(5),
                percentage: 60,
                powerSource: .batteryPower,
                isCharging: false
            ),
            sample(
                at: minuteStart.addingTimeInterval(20),
                percentage: 60,
                powerSource: .acPower,
                isCharging: true
            ),
            sample(
                at: minuteStart.addingTimeInterval(50),
                percentage: 61,
                powerSource: .acPower,
                isCharging: true
            ),
            sample(
                at: minuteStart.addingTimeInterval(65),
                percentage: 62,
                powerSource: .acPower,
                isCharging: true
            )
        ]
        observations.forEach { XCTAssertTrue(store.record($0)) }
        let persistedSamples = store.allSamples()

        try store.stop()
        let reloaded = BatteryHistoryStore(storageURL: storageURL, now: { now })

        XCTAssertEqual(reloaded.allSamples(), persistedSamples)
        XCTAssertGreaterThan(reloaded.count, 1)
        XCTAssertTrue(
            reloaded.allSamples().contains {
                $0.timestamp == minuteStart.addingTimeInterval(20)
                    && $0.powerSource == .acPower
                    && $0.isCharging
            }
        )
        let phases = reloaded.powerPhases(in: .thirtyMinutes, endingAt: now)
        XCTAssertEqual(phases.count, 2)
        XCTAssertFalse(phases[0].isCharging)
        XCTAssertTrue(phases[1].isCharging)
        XCTAssertEqual(phases[1].start, minuteStart.addingTimeInterval(20))
    }

    private func makeStore(now: @escaping () -> Date) -> BatteryHistoryStore {
        BatteryHistoryStore(storageURL: nil, now: now)
    }

    private func sample(
        at timestamp: Date,
        percentage: Int,
        powerSource: PowerSource = .batteryPower,
        isCharging: Bool = false
    ) -> BatteryHistorySample {
        BatteryHistorySample(
            timestamp: timestamp,
            percentage: percentage,
            powerSource: powerSource,
            isCharging: isCharging
        )
    }
}
