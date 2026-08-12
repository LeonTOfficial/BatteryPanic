import AppKit
import SwiftUI
import XCTest
@testable import BatteryPanicApp

final class DashboardRenderingTests: XCTestCase {
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
    func testSmoothedLineKeepsExactSamplesForHoverAndRangeChanges() throws {
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
        XCTAssertEqual(hoverPoint.timestamp, repeatedSample.timestamp)
        XCTAssertEqual(hoverPoint.percentage, Double(repeatedSample.percentage))
        XCTAssertFalse(hoverPoint.isEstimated)

        let thirtyMinuteCount = model.samples.count
        model.selectedRange = .oneDay
        XCTAssertGreaterThan(model.samples.count, thirtyMinuteCount)
        XCTAssertEqual(model.selectedRange, .oneDay)
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
        XCTAssertEqual(segments.map(\.isCharging), [false, true, false])
        XCTAssertEqual(
            segments[0].samples.last?.timestamp,
            now.addingTimeInterval(-900)
        )
        XCTAssertEqual(
            segments[1].samples.first?.timestamp,
            now.addingTimeInterval(-900)
        )
        XCTAssertEqual(
            segments[1].samples.last?.timestamp,
            now.addingTimeInterval(-300)
        )
        XCTAssertEqual(
            segments[2].samples.first?.timestamp,
            now.addingTimeInterval(-300)
        )

        for (index, segment) in segments.enumerated() {
            XCTAssertEqual(segment.samples.first?.isCharging, segment.isCharging)
            XCTAssertTrue(
                segment.samples.dropLast().allSatisfy {
                    $0.isCharging == segment.isCharging
                }
            )

            guard segment.samples.last?.isCharging != segment.isCharging else {
                continue
            }
            XCTAssertLessThan(index + 1, segments.count)
            guard index + 1 < segments.count else { continue }
            let nextSegment = segments[index + 1]
            XCTAssertEqual(
                segment.samples.last?.timestamp,
                nextSegment.samples.first?.timestamp
            )
            XCTAssertEqual(
                segment.samples.last?.isCharging,
                nextSegment.isCharging
            )
        }

        let recordedSamples = Set(historyStore.allSamples().map(\.timestamp))
        XCTAssertTrue(
            segments.flatMap(\.samples).allSatisfy {
                recordedSamples.contains($0.timestamp)
            }
        )
        XCTAssertFalse(
            segments[0].isCharging,
            "AC power without active charging must remain a consumption-colored segment."
        )

        let observedPercentages = model.samples.map { Double($0.percentage) }
        let observedMinimum = try XCTUnwrap(observedPercentages.min())
        let observedMaximum = try XCTUnwrap(observedPercentages.max())
        XCTAssertLessThanOrEqual(model.chartYDomain.lowerBound, observedMinimum)
        XCTAssertGreaterThanOrEqual(model.chartYDomain.upperBound, observedMaximum)
        XCTAssertGreaterThanOrEqual(
            model.chartYDomain.upperBound - model.chartYDomain.lowerBound,
            6
        )
        XCTAssertNotEqual(model.chartYDomain, 0...100)
    }

    @MainActor
    func testReferenceDashboardRendersAsANonEmptyNativeView() throws {
        let now = Date(timeIntervalSince1970: 1_786_286_720)
        let historyStore = BatteryHistoryStore(storageURL: nil, now: { now })
        for minute in 0...30 {
            let timestamp = now.addingTimeInterval(TimeInterval((minute - 30) * 60))
            let isInitialCharge = minute < 5
            let percentage = isInitialCharge
                ? 22 + (minute / 3)
                : 23 - Int((Double(minute - 5) * 5 / 25).rounded(.down))
            historyStore.record(
                BatteryHistorySample(
                    timestamp: timestamp,
                    percentage: percentage,
                    powerSource: isInitialCharge ? .acPower : .batteryPower,
                    isCharging: isInitialCharge
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

        let content = BatteryDashboardView(model: model)
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
        window.backgroundColor = .windowBackgroundColor
        window.contentView = hostingView
        window.orderFrontRegardless()
        defer {
            window.orderOut(nil)
            window.close()
        }

        RunLoop.current.run(until: Date().addingTimeInterval(0.35))
        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()

        let representation = try XCTUnwrap(
            hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)
        )
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)
        let pngData = try XCTUnwrap(representation.representation(using: .png, properties: [:]))

        XCTAssertEqual(hostingView.bounds.width, 426)
        XCTAssertGreaterThanOrEqual(hostingView.bounds.height, 438)
        XCTAssertLessThanOrEqual(hostingView.bounds.height, 442)
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
