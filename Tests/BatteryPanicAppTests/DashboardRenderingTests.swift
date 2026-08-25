import AppKit
import SwiftUI
import XCTest
@testable import BatteryPanicApp

final class DashboardRenderingTests: XCTestCase {
    func testHoverSelectionDeadbandPreventsBoundaryChatterWithoutInterpolating() {
        XCTAssertFalse(
            DashboardHoverSelectionPolicy.shouldSwitch(
                currentX: 40,
                candidateX: 60,
                pointerX: 51
            )
        )
        XCTAssertTrue(
            DashboardHoverSelectionPolicy.shouldSwitch(
                currentX: 40,
                candidateX: 60,
                pointerX: 52
            )
        )
        XCTAssertFalse(
            DashboardHoverSelectionPolicy.shouldSwitch(
                currentX: 60,
                candidateX: 40,
                pointerX: 49
            )
        )
        XCTAssertTrue(
            DashboardHoverSelectionPolicy.shouldSwitch(
                currentX: 60,
                candidateX: 40,
                pointerX: 48
            )
        )
    }

    @MainActor
    func testAppKitHoverTrackingPublishesMovementDuringNativeMenuTracking() throws {
        let view = DashboardHoverTrackingView.HoverTrackingNSView(
            frame: NSRect(x: 0, y: 0, width: 266, height: 112)
        )

        var reportedLocation: CGPoint?
        var didExit = false
        view.onMove = { reportedLocation = $0 }
        view.onExit = { didExit = true }
        view.updateTrackingAreas()

        let options = view.trackingAreas.reduce(into: NSTrackingArea.Options()) {
            $0.formUnion($1.options)
        }
        XCTAssertTrue(options.contains(.activeAlways))
        XCTAssertTrue(options.contains(.mouseMoved))
        XCTAssertTrue(options.contains(.mouseEnteredAndExited))

        let event = try XCTUnwrap(
            NSEvent.mouseEvent(
                with: .mouseMoved,
                location: NSPoint(x: 80, y: 45),
                modifierFlags: [],
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                eventNumber: 1,
                clickCount: 0,
                pressure: 0
            )
        )
        view.mouseMoved(with: event)
        XCTAssertNotNil(reportedLocation)
        XCTAssertTrue(view.bounds.contains(try XCTUnwrap(reportedLocation)))

        view.mouseExited(with: event)
        XCTAssertTrue(didExit)
    }

    @MainActor
    func testFinishingChargeCopyRemainsExplicitWhenChargingFlagIsFalse() throws {
        let defaultsName = "BatteryPanicDashboardFinishingChargeTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 10,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: BatteryHistoryStore(storageURL: nil),
            defaults: defaults
        )

        model.update(
            status: BatteryStatus(
                percentage: 100,
                powerSource: .acPower,
                isCharging: false,
                isFinishingCharge: true,
                hasBattery: true,
                timeRemainingMinutes: 8
            ),
            settings: settings
        )

        XCTAssertEqual(model.statusTitle, "Finishing charge")
        XCTAssertEqual(model.statusSubtitle, "About 8m until full")
    }

    @MainActor
    func testHoverSelectsOnlyExactSamplesUsedByTheSmoothedLine() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        let observations: [(TimeInterval, Int)] = [
            (-7_200, 28),
            (-1_800, 22),
            (-1_740, 22),
            (-1_680, 22),
            (-1_200, 21),
            (-600, 20),
            (0, 18)
        ]
        for (offset, percentage) in observations {
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(offset),
                    percentage: percentage,
                    powerSource: .batteryPower,
                    isCharging: false
                )
            )
        }

        let suiteName = "BatteryPanicDashboardTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 18,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true,
                timestamp: now
            ),
            settings: settings
        )

        XCTAssertLessThan(model.visualLineSamples.count, model.samples.count)
        let repeatedSample = try XCTUnwrap(
            model.samples.first(where: { $0.timestamp == now.addingTimeInterval(-1_740) })
        )
        let hoverPoint = try XCTUnwrap(model.nearestChartPoint(to: repeatedSample.timestamp))
        XCTAssertNotEqual(hoverPoint.timestamp, repeatedSample.timestamp)
        XCTAssertTrue(model.renderedLineSamples.contains { $0.timestamp == hoverPoint.timestamp })
        let storedSample = try XCTUnwrap(
            historyStore.allSamples().first { $0.timestamp == hoverPoint.timestamp }
        )
        XCTAssertEqual(hoverPoint.percentage, Double(storedSample.percentage))
        XCTAssertFalse(hoverPoint.isEstimated)

        let renderedLineDataset = model.visualLineSegments.flatMap(\.samples)
        for selectableSample in model.renderedLineSamples {
            XCTAssertTrue(
                renderedLineDataset.contains(selectableSample),
                "Every hover sample must also be a control point of the visible spline."
            )
            XCTAssertTrue(
                historyStore.allSamples().contains(selectableSample),
                "Every hover value must remain an exact recorded measurement."
            )
        }

        let thirtyMinuteCount = model.samples.count
        model.selectedRange = .oneDay
        XCTAssertGreaterThan(model.samples.count, thirtyMinuteCount)
        XCTAssertEqual(model.selectedRange, .oneDay)
    }

    @MainActor
    func testShortHistoryStartsAtLeadingEdgeWithoutInventingAnOlderSample() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        let firstRecordedTimestamp = now.addingTimeInterval(-60)
        historyStore.record(
            BatteryHistorySample(
                timestamp: firstRecordedTimestamp,
                percentage: 51,
                powerSource: .batteryPower,
                isCharging: false
            )
        )
        historyStore.record(
            BatteryHistorySample(
                timestamp: now,
                percentage: 50,
                powerSource: .batteryPower,
                isCharging: false
            )
        )

        let defaultsName = "BatteryPanicDashboardShortHistoryTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 50,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true,
                timestamp: now
            ),
            settings: settings
        )

        XCTAssertEqual(model.chartStart, firstRecordedTimestamp)
        XCTAssertGreaterThan(model.chartStart, model.rangeStart)
        XCTAssertEqual(model.renderedLineSamples.first?.timestamp, model.chartStart)
        XCTAssertTrue(
            historyStore.allSamples().contains { $0.timestamp == model.chartStart },
            "The leading chart point must remain an actual recorded measurement"
        )
    }

    @MainActor
    func testLineSegmentsUseOnlyRecordedChargingTransitions() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        let observations: [(TimeInterval, Int, PowerSource, Bool)] = [
            (-1_500, 31, .batteryPower, false),
            (-1_200, 30, .acPower, false),
            (-900, 30, .acPower, true),
            (-600, 31, .acPower, true),
            (-300, 31, .acPower, false),
            (0, 30, .batteryPower, false)
        ]
        for (offset, percentage, powerSource, isCharging) in observations {
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(offset),
                    percentage: percentage,
                    powerSource: powerSource,
                    isCharging: isCharging
                )
            )
        }

        let suiteName = "BatteryPanicDashboardSegmentsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 30,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true,
                timestamp: now
            ),
            settings: settings
        )

        let segments = model.visualLineSegments
        XCTAssertEqual(
            segments.map(\.style),
            [.discharging, .connectedNotCharging, .charging, .connectedNotCharging]
        )
        XCTAssertEqual(
            segments[0].samples.last?.timestamp,
            now.addingTimeInterval(-1_200)
        )
        XCTAssertEqual(
            segments[1].samples.first?.timestamp,
            now.addingTimeInterval(-1_200)
        )
        XCTAssertEqual(
            segments[2].samples.first?.timestamp,
            now.addingTimeInterval(-900)
        )
        XCTAssertEqual(
            segments[3].samples.first?.timestamp,
            now.addingTimeInterval(-300)
        )

        for (index, segment) in segments.enumerated() {
            XCTAssertEqual(
                segment.samples.first.map(model.lineStyle(for:)),
                segment.style
            )
            XCTAssertTrue(
                segment.samples.dropLast().allSatisfy {
                    model.lineStyle(for: $0) == segment.style
                }
            )

            guard segment.samples.last.map(model.lineStyle(for:)) != segment.style else {
                continue
            }
            guard index + 1 < segments.count else { continue }
            let nextSegment = segments[index + 1]
            XCTAssertEqual(
                segment.samples.last?.timestamp,
                nextSegment.samples.first?.timestamp
            )
            XCTAssertEqual(
                segment.samples.last.map(model.lineStyle(for:)),
                nextSegment.style
            )
        }

        let recordedSamples = Set(historyStore.allSamples().map(\.timestamp))
        XCTAssertTrue(
            segments.flatMap(\.samples).allSatisfy {
                recordedSamples.contains($0.timestamp)
            }
        )
        XCTAssertEqual(segments[1].style, .connectedNotCharging)
        XCTAssertEqual(
            model.chargingMarkerSamples.map(\.timestamp),
            [now.addingTimeInterval(-600)]
        )

        XCTAssertEqual(model.chartYDomain, -8...108)
    }

    @MainActor
    func testDayAndWeekRenderLongRecordingPausesAsNeutralRealEndpointGaps() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        let observations: [(TimeInterval, Int)] = [
            (-4 * 60 * 60, 80),
            (-4 * 60 * 60 + 60, 79),
            (-2 * 60 * 60, 77),
            (-2 * 60 * 60 + 60, 76)
        ]
        for (offset, percentage) in observations {
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(offset),
                    percentage: percentage,
                    powerSource: .batteryPower,
                    isCharging: false
                )
            )
        }

        let defaultsName = "BatteryPanicDashboardNoDataGapTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 76,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true,
                timestamp: now
            ),
            settings: settings
        )
        let recordedTimestamps = Set(historyStore.allSamples().map(\.timestamp))

        for range in [BatteryHistoryRange.oneDay, .sevenDays] {
            model.selectRange(range)
            let gaps = model.visualLineSegments.filter { $0.style == .noData }
            XCTAssertEqual(gaps.count, 1)
            XCTAssertEqual(gaps[0].samples.count, 2)
            XCTAssertTrue(
                gaps[0].samples.allSatisfy { recordedTimestamps.contains($0.timestamp) },
                "A missing-history gap may connect only actual recorded endpoints"
            )
            XCTAssertTrue(
                model.renderedLineSamples.allSatisfy {
                    recordedTimestamps.contains($0.timestamp)
                },
                "Gap rendering must not create hoverable measurements"
            )
        }
    }

    @MainActor
    func testDayDownsamplingDoesNotCreateFalseMissingHistoryGaps() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        for minute in -360...0 {
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(TimeInterval(minute * 60)),
                    percentage: 80 + minute / 60,
                    powerSource: .batteryPower,
                    isCharging: false
                )
            )
        }

        let defaultsName = "BatteryPanicDashboardContinuousHistoryTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 80,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true,
                timestamp: now
            ),
            settings: settings
        )
        model.selectRange(.oneDay)

        XCTAssertGreaterThan(historyStore.count, model.samples.count)
        XCTAssertFalse(model.visualLineSegments.contains { $0.style == .noData })
    }

    @MainActor
    func testEveryVisibleChargingSectionGetsOneMarkerAtItsNearestRealMidpoint() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        let observations: [(TimeInterval, Int, PowerSource, Bool)] = [
            (-1_800, 40, .batteryPower, false),
            (-1_500, 41, .acPower, true),
            (-1_200, 42, .acPower, true),
            (-900, 42, .acPower, false),
            (-600, 41, .batteryPower, false),
            (-300, 42, .acPower, true),
            (-120, 43, .acPower, true),
            (0, 44, .acPower, true)
        ]
        for (offset, percentage, powerSource, isCharging) in observations {
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(offset),
                    percentage: percentage,
                    powerSource: powerSource,
                    isCharging: isCharging
                )
            )
        }

        let suiteName = "BatteryPanicDashboardChargingMarkersTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 44,
                powerSource: .acPower,
                isCharging: true,
                hasBattery: true,
                timestamp: now
            ),
            settings: settings
        )

        XCTAssertEqual(
            model.chargingMarkerSamples.map(\.timestamp),
            [now.addingTimeInterval(-1_200), now.addingTimeInterval(-120)]
        )
        let recordedSamples = historyStore.allSamples()
        XCTAssertTrue(
            model.chargingMarkerSamples.allSatisfy(recordedSamples.contains)
        )
        XCTAssertTrue(
            model.chargingMarkerSamples.allSatisfy(
                model.renderedLineSamples.contains
            )
        )
    }

    @MainActor
    func testHoverAxisUsesRelativeLabelsForCompleteShortRanges() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        for minute in [-(7 * 24 * 60), -(24 * 60), -60, -30, 0] {
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(TimeInterval(minute * 60)),
                    percentage: 50,
                    powerSource: .batteryPower,
                    isCharging: false
                )
            )
        }
        let defaultsName = "BatteryPanicDashboardAxisTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 50,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true,
                timestamp: now
            ),
            settings: settings
        )

        let expectedLabels: [(BatteryHistoryRange, [String])] = [
            (.thirtyMinutes, ["30m", "25m", "20m", "15m", "10m", "5m", "now"]),
            (.oneHour, ["1h", "50m", "40m", "30m", "20m", "10m", "now"])
        ]
        for (range, labels) in expectedLabels {
            model.selectRange(range)
            XCTAssertEqual(model.hoverTimeAxisTicks.map(\.label), labels)
            XCTAssertEqual(model.hoverTimeAxisTicks.first?.timestamp, model.chartStart)
            XCTAssertEqual(model.hoverTimeAxisTicks.last?.timestamp, model.rangeEnd)
        }
    }

    @MainActor
    func testDayHoverAxisUsesRealFourHourClockBoundaries() throws {
        let (model, _) = try makeCompleteCalendarAxisModel()
        let calendar = Calendar.current

        model.selectRange(.oneDay)
        let ticks = model.hoverTimeAxisTicks
        let clockTicks = ticks.filter { $0.label != "now" }

        XCTAssertFalse(clockTicks.isEmpty)
        XCTAssertEqual(ticks.last?.label, "now")
        XCTAssertEqual(ticks.last?.timestamp, model.rangeEnd)
        if let lastClockTick = clockTicks.last {
            XCTAssertGreaterThanOrEqual(
                model.rangeEnd.timeIntervalSince(lastClockTick.timestamp),
                2 * 60 * 60
            )
        }
        for tick in clockTicks {
            let hour = calendar.component(.hour, from: tick.timestamp)
            XCTAssertEqual(calendar.component(.minute, from: tick.timestamp), 0)
            XCTAssertEqual(calendar.component(.second, from: tick.timestamp), 0)
            XCTAssertEqual(hour % 4, 0)
            XCTAssertEqual(tick.label, String(format: "%02d:00", hour))
            XCTAssertGreaterThan(tick.timestamp, model.chartStart)
            XCTAssertLessThanOrEqual(tick.timestamp, model.rangeEnd)
        }
    }

    @MainActor
    func testWeekHoverAxisUsesRealLocalWeekdays() throws {
        let (model, _) = try makeCompleteCalendarAxisModel()
        let calendar = Calendar.current
        let weekdayLabels = Set(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])

        model.selectRange(.sevenDays)
        let ticks = model.hoverTimeAxisTicks

        XCTAssertFalse(ticks.isEmpty)
        XCTAssertTrue(ticks.allSatisfy { weekdayLabels.contains($0.label) })
        XCTAssertFalse(ticks.map(\.label).contains("now"))
        XCTAssertFalse(ticks.contains { $0.label.contains(":") })
        for tick in ticks {
            XCTAssertEqual(tick.timestamp, calendar.startOfDay(for: tick.timestamp))
            XCTAssertGreaterThan(tick.timestamp, model.chartStart)
            XCTAssertLessThanOrEqual(tick.timestamp, model.rangeEnd)
        }
        for pair in zip(ticks, ticks.dropFirst()) {
            XCTAssertEqual(
                calendar.date(byAdding: .day, value: 1, to: pair.0.timestamp),
                pair.1.timestamp
            )
        }
    }

    @MainActor
    private func makeCompleteCalendarAxisModel() throws -> (
        BatteryDashboardViewModel,
        UserDefaults
    ) {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        for hour in stride(from: -(7 * 24), through: 0, by: 1) {
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(TimeInterval(hour * 60 * 60)),
                    percentage: 50 + (hour % 3),
                    powerSource: .batteryPower,
                    isCharging: false
                )
            )
        }
        let defaultsName = "BatteryPanicDashboardCalendarAxisTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
        defaults.removePersistentDomain(forName: defaultsName)
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 50,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true,
                timestamp: now
            ),
            settings: settings
        )
        return (model, defaults)
    }

    @MainActor
    func testHoverAxisReportsShortNewHistoryHonestly() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        for seconds in stride(from: -60, through: 0, by: 10) {
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(TimeInterval(seconds)),
                    percentage: 50,
                    powerSource: .batteryPower,
                    isCharging: false
                )
            )
        }
        let defaultsName = "BatteryPanicDashboardShortAxisTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 50,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true,
                timestamp: now
            ),
            settings: settings
        )

        XCTAssertFalse(model.hoverTimeAxisTicks.first?.label.contains("ago") == true)
        XCTAssertEqual(model.hoverTimeAxisTicks.last?.label, "now")
        XCTAssertFalse(model.hoverTimeAxisTicks.map(\.label).contains("30m"))
    }

    @MainActor
    func testShortHistoryKeepsFullDayAndWeekCalendarAxesWithoutInventingSamples() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        for seconds in stride(from: -120, through: 0, by: 30) {
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(TimeInterval(seconds)),
                    percentage: 50,
                    powerSource: .batteryPower,
                    isCharging: false
                )
            )
        }
        let defaultsName = "BatteryPanicDashboardShortCalendarAxisTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 50,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true,
                timestamp: now
            ),
            settings: settings
        )
        let recordedSamples = historyStore.allSamples()

        model.selectRange(.oneDay)
        XCTAssertEqual(model.chartStart, model.rangeStart)
        XCTAssertGreaterThan(model.chartRevealStartFraction, 0.8)
        XCTAssertGreaterThanOrEqual(model.hoverTimeAxisTicks.count, 6)
        XCTAssertEqual(model.hoverTimeAxisTicks.last?.label, "now")

        model.selectRange(.sevenDays)
        XCTAssertEqual(model.chartStart, model.rangeStart)
        XCTAssertGreaterThan(model.chartRevealStartFraction, 0.95)
        XCTAssertEqual(model.hoverTimeAxisTicks.count, 7)
        XCTAssertTrue(
            model.hoverTimeAxisTicks.allSatisfy {
                ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].contains($0.label)
            }
        )
        XCTAssertEqual(historyStore.allSamples(), recordedSamples)
    }

    @MainActor
    func testMenuOpenResetsRangeAndInlinePickerCollapsesAfterSelection() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        let defaultsName = "BatteryPanicDashboardRangeTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        defaults.set("1w", forKey: "menuDashboardHistoryRange")
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )

        XCTAssertEqual(model.selectedRange, .thirtyMinutes)
        model.toggleRangePicker()
        XCTAssertTrue(model.isRangePickerExpanded)
        model.selectRange(.oneDay)
        XCTAssertEqual(model.selectedRange, .oneDay)
        XCTAssertFalse(model.isRangePickerExpanded)

        model.toggleRangePicker()
        model.prepareForMenuOpening()
        XCTAssertEqual(model.selectedRange, .thirtyMinutes)
        XCTAssertFalse(model.isRangePickerExpanded)
        XCTAssertEqual(defaults.string(forKey: "menuDashboardHistoryRange"), "1w")
    }

    @MainActor
    func testForecastIsCalculatedPerSupportedRangeAndOmittedForWeek() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        let observations: [(Int, Int)] = [
            (-24 * 60, 95),
            (-12 * 60, 90),
            (-2 * 60, 88)
        ] + stride(from: -60, through: 0, by: 10).map { minute in
            (minute, 80 - minute / 10)
        }
        for (minute, percentage) in observations {
            historyStore.record(
                BatteryHistorySample(
                    timestamp: now.addingTimeInterval(TimeInterval(minute * 60)),
                    percentage: percentage,
                    powerSource: .batteryPower,
                    isCharging: false
                )
            )
        }
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: "BatteryPanicDashboardForecastTests.\(UUID().uuidString)")
        )
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: false,
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 80,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true,
                timestamp: now
            ),
            settings: settings
        )

        XCTAssertEqual(model.forecast?.horizon, .thirtyMinutes)
        XCTAssertNotNil(model.projectedChartPoint)
        model.selectRange(.oneHour)
        XCTAssertEqual(model.forecast?.horizon, .oneHour)
        XCTAssertNotNil(model.projectedChartPoint)
        model.selectRange(.oneDay)
        XCTAssertEqual(model.forecast?.horizon, .oneDay)
        XCTAssertNotNil(model.projectedChartPoint)
        model.selectRange(.sevenDays)
        XCTAssertNil(model.forecast)
        XCTAssertNil(model.projectedChartPoint)
    }

    @MainActor
    func testReferenceDashboardRendersAsANonEmptyNativeView() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        if ProcessInfo.processInfo.environment[
            "BATTERY_PANIC_DASHBOARD_PREVIEW_HISTORY_GAPS"
        ] == "1" {
            let observations: [(TimeInterval, Int)] = [
                (-12 * 60 * 60, 72),
                (-12 * 60 * 60 + 60, 71),
                (-5 * 60 * 60, 62),
                (-5 * 60 * 60 + 60, 61),
                (-2 * 60 * 60, 56),
                (-2 * 60 * 60 + 60, 55)
            ]
            for (offset, percentage) in observations {
                historyStore.record(
                    BatteryHistorySample(
                        timestamp: now.addingTimeInterval(offset),
                        percentage: percentage,
                        powerSource: .batteryPower,
                        isCharging: false
                    )
                )
            }
        } else if ProcessInfo.processInfo.environment[
            "BATTERY_PANIC_DASHBOARD_PREVIEW_SHORT_HISTORY"
        ] == "1" {
            for minute in stride(from: -150, through: 0, by: 10) {
                historyStore.record(
                    BatteryHistorySample(
                        timestamp: now.addingTimeInterval(TimeInterval(minute * 60)),
                        percentage: 75 - ((minute + 150) / 10),
                        powerSource: .batteryPower,
                        isCharging: false
                    )
                )
            }
        } else {
            DashboardQAHistoryFixture.populate(historyStore, endingAt: now)
        }

        let suiteName = "BatteryPanicDashboardTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AlarmSettingsSnapshot(
            thresholdPercentage: 20,
            chargeReminderEnabled: true,
            chargeReminderThresholdPercentage: 80,
            pulseEnabled: true,
            pulseSpeed: 1,
            pulseIntensity: 1,
            soundEnabled: true,
            selectedSoundName: WarningSound.defaultSound.name,
            isPaused: true,
            pauseUntil: Date().addingTimeInterval(24 * 60),
            hasCompletedOnboarding: true
        )
        let model = BatteryDashboardViewModel(
            settings: settings,
            historyStore: historyStore,
            defaults: defaults
        )
        model.update(
            status: BatteryStatus(
                percentage: 18,
                powerSource: .batteryPower,
                isCharging: false,
                hasBattery: true,
                health: .good,
                timeRemainingMinutes: 42,
                timestamp: now
            ),
            settings: settings
        )

        switch ProcessInfo.processInfo.environment["BATTERY_PANIC_DASHBOARD_PREVIEW_RANGE"] {
        case "1h":
            model.selectRange(.oneHour)
        case "day":
            model.selectRange(.oneDay)
        case "week":
            model.selectRange(.sevenDays)
        default:
            break
        }

        let isPickerPreview = ProcessInfo.processInfo.environment[
            "BATTERY_PANIC_DASHBOARD_PREVIEW_PICKER"
        ] == "1"
        let capturesAnimatedPicker = ProcessInfo.processInfo.environment[
            "BATTERY_PANIC_DASHBOARD_PREVIEW_PICKER_ANIMATED"
        ] == "1"
        if isPickerPreview && !capturesAnimatedPicker {
            model.toggleRangePicker()
        }

        let initialHoveredPoint: DashboardChartPoint?
        if ProcessInfo.processInfo.environment["BATTERY_PANIC_DASHBOARD_PREVIEW_HOVER"] == "1",
           let sample = model.renderedLineSamples.dropLast().last
        {
            initialHoveredPoint = model.nearestChartPoint(to: sample.timestamp)
        } else {
            initialHoveredPoint = nil
        }

        let capturesAnimatedReveal = ProcessInfo.processInfo.environment[
            "BATTERY_PANIC_DASHBOARD_PREVIEW_ANIMATED"
        ] == "1"

        let content = BatteryDashboardView(
            model: model,
            reduceMotionOverride: !capturesAnimatedReveal,
            initialHoveredPoint: initialHoveredPoint
        )
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, .light)
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(x: 0, y: 0, width: 426, height: 505)
        hostingView.appearance = NSAppearance(named: .aqua)

        let window = NSWindow(
            contentRect: hostingView.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
        window.backgroundColor = .windowBackgroundColor
        window.contentView = hostingView
        window.orderFront(nil)
        defer {
            window.orderOut(nil)
            window.close()
        }

        if capturesAnimatedPicker {
            RunLoop.current.run(until: Date().addingTimeInterval(0.08))
            withAnimation(
                .interactiveSpring(response: 0.34, dampingFraction: 0.86, blendDuration: 0.12)
            ) {
                model.toggleRangePicker()
            }
        }
        let pickerFrameDelay = ProcessInfo.processInfo.environment[
            "BATTERY_PANIC_DASHBOARD_PREVIEW_PICKER_DELAY"
        ].flatMap(TimeInterval.init) ?? 0.16
        let captureDelay: TimeInterval
        if capturesAnimatedPicker {
            captureDelay = pickerFrameDelay
        } else {
            captureDelay = capturesAnimatedReveal ? 0.28 : 0.35
        }
        RunLoop.current.run(until: Date().addingTimeInterval(captureDelay))
        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()

        let representation = try XCTUnwrap(
            hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)
        )
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        let pngData = try XCTUnwrap(representation.representation(using: .png, properties: [:]))

        XCTAssertEqual(hostingView.bounds.width, 426)
        if isPickerPreview && !capturesAnimatedPicker {
            XCTAssertGreaterThanOrEqual(hostingView.bounds.height, 475)
            XCTAssertLessThanOrEqual(hostingView.bounds.height, 485)
        } else if !capturesAnimatedPicker {
            XCTAssertGreaterThanOrEqual(hostingView.bounds.height, 438)
            XCTAssertLessThanOrEqual(hostingView.bounds.height, 442)
        } else {
            XCTAssertGreaterThan(hostingView.bounds.height, 440)
            XCTAssertLessThanOrEqual(hostingView.bounds.height, 490)
        }
        XCTAssertGreaterThan(pngData.count, 20_000, "The dashboard render should contain real UI, not a blank frame.")

        if let outputPath = ProcessInfo.processInfo.environment["BATTERY_PANIC_DASHBOARD_PREVIEW_PATH"] {
            let outputURL = URL(fileURLWithPath: outputPath)
            try FileManager.default.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try pngData.write(to: outputURL, options: .atomic)
        }
    }
}
