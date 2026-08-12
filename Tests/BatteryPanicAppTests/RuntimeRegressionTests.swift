import Foundation
import IOKit.ps
import XCTest
@testable import BatteryPanicApp

final class AppSettingsStoreRegressionTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "BatteryPanicTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(true, forKey: "migratedLegacyBundleSettings")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testOnboardingIsOnlyRequiredForANewInstallation() {
        let freshStore = AppSettingsStore(defaults: defaults)
        XCTAssertFalse(freshStore.snapshot().hasCompletedOnboarding)

        freshStore.setHasCompletedOnboarding(true)
        defaults.set("0.1.0", forKey: "completedOnboardingVersion")

        let updatedStore = AppSettingsStore(defaults: defaults)
        XCTAssertTrue(updatedStore.snapshot().hasCompletedOnboarding)

        updatedStore.setHasCompletedOnboarding(false)
        XCTAssertFalse(updatedStore.snapshot().hasCompletedOnboarding)
    }

    func testLegacyCompletedVersionMigratesWithoutShowingOnboardingAgain() {
        defaults.set(false, forKey: "hasCompletedOnboarding")
        defaults.set("0.4.0", forKey: "completedOnboardingVersion")

        let store = AppSettingsStore(defaults: defaults)

        XCTAssertTrue(store.snapshot().hasCompletedOnboarding)
        XCTAssertTrue(defaults.bool(forKey: "hasCompletedOnboarding"))
    }

    func testNonFinitePulseValuesResetToSafeDefaults() {
        defaults.set(Double.nan, forKey: "pulseSpeed")
        defaults.set(Double.infinity, forKey: "pulseIntensity")
        let store = AppSettingsStore(defaults: defaults)

        let snapshot = store.snapshot()

        XCTAssertEqual(snapshot.pulseSpeed, 1.0)
        XCTAssertEqual(snapshot.pulseIntensity, 1.0)
        XCTAssertEqual(defaults.double(forKey: "pulseSpeed"), 1.0)
        XCTAssertEqual(defaults.double(forKey: "pulseIntensity"), 1.0)

        store.setPulseSpeed(-Double.infinity)
        store.setPulseIntensity(Double.nan)
        XCTAssertEqual(store.snapshot().pulseSpeed, 1.0)
        XCTAssertEqual(store.snapshot().pulseIntensity, 1.0)
    }
}

final class IOKitBatteryProviderRegressionTests: XCTestCase {
    func testMissingIOKitResultReturnsUnavailableStatus() {
        let provider = IOKitBatteryProvider(readDescriptions: { nil })

        let status = provider.currentStatus()

        XCTAssertFalse(status.hasBattery)
        XCTAssertEqual(status.powerSource, .unknown)
    }

    func testInjectedPowerSourceDescriptionProducesRealStatus() {
        let provider = IOKitBatteryProvider(readDescriptions: {
            [[
                kIOPSCurrentCapacityKey: 42,
                kIOPSMaxCapacityKey: 100,
                kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue,
                kIOPSIsChargingKey: false,
                kIOPSTimeToEmptyKey: 75
            ]]
        })

        let status = provider.currentStatus()

        XCTAssertTrue(status.hasBattery)
        XCTAssertEqual(status.percentage, 42)
        XCTAssertEqual(status.powerSource, .batteryPower)
        XCTAssertEqual(status.timeRemainingMinutes, 75)
    }

    func testOfficialIOKitMetadataIsMappedToTypedBatteryStatus() {
        let provider = IOKitBatteryProvider(readDescriptions: {
            [[
                kIOPSCurrentCapacityKey: 100,
                kIOPSMaxCapacityKey: 100,
                kIOPSPowerSourceStateKey: kIOPSACPowerValue,
                kIOPSIsChargingKey: true,
                kIOPSIsChargedKey: true,
                kIOPSIsFinishingChargeKey: true,
                kIOPSBatteryHealthKey: kIOPSFairValue,
                kIOPSBatteryHealthConditionKey: kIOPSCheckBatteryValue,
                kIOPSTimeToFullChargeKey: 12
            ]]
        })

        let status = provider.currentStatus()

        XCTAssertEqual(status.powerState, .charging)
        XCTAssertTrue(status.isCharged)
        XCTAssertTrue(status.isFinishingCharge)
        XCTAssertEqual(status.health, .fair)
        XCTAssertEqual(status.health?.displayName, "Fair")
        XCTAssertEqual(status.healthCondition, .checkBattery)
        XCTAssertEqual(status.healthCondition?.displayName, "Check Battery")
        XCTAssertEqual(status.timeRemainingMinutes, 12)
    }

    func testConnectedBatteryNotChargingRemainsDistinctFromCharging() {
        let provider = IOKitBatteryProvider(readDescriptions: {
            [[
                kIOPSCurrentCapacityKey: 82,
                kIOPSMaxCapacityKey: 100,
                kIOPSPowerSourceStateKey: kIOPSACPowerValue,
                kIOPSIsChargingKey: false,
                kIOPSIsChargedKey: false,
                kIOPSTimeToEmptyKey: 99
            ]]
        })

        let status = provider.currentStatus()

        XCTAssertEqual(status.powerState, .connectedNotCharging)
        XCTAssertTrue(status.isPluggedIn)
        XCTAssertFalse(status.isCharging)
        XCTAssertNil(status.timeRemainingMinutes)
    }

    func testFinishingChargeIsAnEffectiveChargingStateWithTimeToFull() {
        let provider = IOKitBatteryProvider(readDescriptions: {
            [[
                kIOPSCurrentCapacityKey: 99,
                kIOPSMaxCapacityKey: 100,
                kIOPSPowerSourceStateKey: kIOPSACPowerValue,
                kIOPSIsChargingKey: false,
                kIOPSIsFinishingChargeKey: true,
                kIOPSTimeToFullChargeKey: 8
            ]]
        })

        let status = provider.currentStatus()

        XCTAssertFalse(status.isCharging)
        XCTAssertTrue(status.isFinishingCharge)
        XCTAssertTrue(status.isActivelyCharging)
        XCTAssertEqual(status.powerState, .charging)
        XCTAssertEqual(status.timeRemainingMinutes, 8)
        XCTAssertEqual(BatteryFormatter.longStatus(for: status), "99% on charging")
        XCTAssertEqual(BatteryFormatter.timeRemainingText(for: status), "About 8m until full")
    }

    func testUnknownHealthValuesArePreservedAndBlankValuesAreAbsent() {
        let futureProvider = IOKitBatteryProvider(readDescriptions: {
            [[
                kIOPSCurrentCapacityKey: 70,
                kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue,
                kIOPSIsChargingKey: false,
                kIOPSBatteryHealthKey: "  Excellent  ",
                kIOPSBatteryHealthConditionKey: "  Service Soon  "
            ]]
        })
        let blankProvider = IOKitBatteryProvider(readDescriptions: {
            [[
                kIOPSCurrentCapacityKey: 70,
                kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue,
                kIOPSIsChargingKey: false,
                kIOPSBatteryHealthKey: "   ",
                kIOPSBatteryHealthConditionKey: "\n"
            ]]
        })

        let futureStatus = futureProvider.currentStatus()
        let blankStatus = blankProvider.currentStatus()

        XCTAssertEqual(futureStatus.health, .unknown("Excellent"))
        XCTAssertEqual(futureStatus.healthCondition, .unknown("Service Soon"))
        XCTAssertNil(blankStatus.health)
        XCTAssertNil(blankStatus.healthCondition)
    }
}

final class BatteryStatusAppearanceRegressionTests: XCTestCase {
    func testConnectedNotChargingAppearanceDoesNotClaimCharging() {
        let status = BatteryStatus(
            percentage: 82,
            powerSource: .acPower,
            isCharging: false,
            hasBattery: true
        )

        let appearance = BatteryStatusAppearance.appearance(for: status, threshold: 10)

        XCTAssertEqual(appearance.level, .healthy)
        XCTAssertEqual(appearance.title, "82% on power adapter")
        XCTAssertEqual(appearance.subtitle, "Connected, not charging.")
        XCTAssertFalse(appearance.showsBolt)
        XCTAssertEqual(BatteryFormatter.menuTitle(for: status, threshold: 10), "82%")
    }

    func testChargedAndFinishingChargeAppearancesAreExplicit() {
        let charged = BatteryStatus(
            percentage: 100,
            powerSource: .acPower,
            isCharging: false,
            isCharged: true,
            hasBattery: true
        )
        let finishing = BatteryStatus(
            percentage: 100,
            powerSource: .acPower,
            isCharging: false,
            isFinishingCharge: true,
            hasBattery: true
        )

        let chargedAppearance = BatteryStatusAppearance.appearance(for: charged, threshold: 10)
        let finishingAppearance = BatteryStatusAppearance.appearance(for: finishing, threshold: 10)

        XCTAssertEqual(chargedAppearance.title, "100% charged")
        XCTAssertFalse(chargedAppearance.showsBolt)
        XCTAssertEqual(finishingAppearance.level, .charging)
        XCTAssertEqual(finishingAppearance.title, "100% finishing charge")
        XCTAssertTrue(finishingAppearance.showsBolt)
    }
}

final class BatteryMonitorRegressionTests: XCTestCase {
    func testRefreshesNeverOverlap() {
        let firstStarted = expectation(description: "first request started")
        let secondStarted = expectation(description: "pending request started")
        let firstUpdate = expectation(description: "first update")
        let provider = BlockingBatteryProvider(
            statuses: [Self.status(percentage: 21), Self.status(percentage: 20)],
            onInvocation: { invocation in
                if invocation == 1 { firstStarted.fulfill() }
                if invocation == 2 { secondStarted.fulfill() }
            }
        )
        let monitor = BatteryMonitor(provider: provider, interval: 3_600)
        monitor.onStatusUpdate = { _ in firstUpdate.fulfill() }

        monitor.start()
        wait(for: [firstStarted], timeout: 1)
        monitor.refresh()
        monitor.refresh()
        Thread.sleep(forTimeInterval: 0.05)
        XCTAssertEqual(provider.invocationCount, 1)
        XCTAssertEqual(provider.maximumConcurrentRequests, 1)

        provider.release(invocation: 1)
        wait(for: [firstUpdate, secondStarted], timeout: 1)
        XCTAssertEqual(provider.maximumConcurrentRequests, 1)

        monitor.onStatusUpdate = nil
        provider.release(invocation: 2)
        monitor.stop()
    }

    func testRestartDropsStaleResultAndPublishesNewGeneration() {
        let firstStarted = expectation(description: "old generation started")
        let secondStarted = expectation(description: "new generation started")
        let update = expectation(description: "new generation published")
        let provider = BlockingBatteryProvider(
            statuses: [Self.status(percentage: 9), Self.status(percentage: 47)],
            onInvocation: { invocation in
                if invocation == 1 { firstStarted.fulfill() }
                if invocation == 2 { secondStarted.fulfill() }
            }
        )
        let monitor = BatteryMonitor(provider: provider, interval: 3_600)
        var received: [Int] = []
        monitor.onStatusUpdate = { status in
            received.append(status.percentage)
            update.fulfill()
        }

        monitor.start()
        wait(for: [firstStarted], timeout: 1)
        monitor.stop()
        monitor.start()
        provider.release(invocation: 1)
        wait(for: [secondStarted], timeout: 1)
        provider.release(invocation: 2)
        wait(for: [update], timeout: 1)

        XCTAssertEqual(received, [47])
        XCTAssertEqual(provider.maximumConcurrentRequests, 1)
        monitor.stop()
    }

    func testStopDropsLateResult() {
        let started = expectation(description: "request started")
        let noUpdate = expectation(description: "late result ignored")
        noUpdate.isInverted = true
        let provider = BlockingBatteryProvider(
            statuses: [Self.status(percentage: 31)],
            onInvocation: { _ in started.fulfill() }
        )
        let monitor = BatteryMonitor(provider: provider, interval: 3_600)
        monitor.onStatusUpdate = { _ in noUpdate.fulfill() }

        monitor.start()
        wait(for: [started], timeout: 1)
        monitor.stop()
        provider.release(invocation: 1)
        wait(for: [noUpdate], timeout: 0.2)
    }

    private static func status(percentage: Int) -> BatteryStatus {
        BatteryStatus(
            percentage: percentage,
            powerSource: .batteryPower,
            isCharging: false,
            hasBattery: true
        )
    }
}

final class OverlayAnimationPolicyTests: XCTestCase {
    func testPulseAndReduceMotionControlAnimation() {
        XCTAssertTrue(OverlayAnimationPolicy.shouldAnimate(pulseEnabled: true, reduceMotion: false))
        XCTAssertFalse(OverlayAnimationPolicy.shouldAnimate(pulseEnabled: false, reduceMotion: false))
        XCTAssertFalse(OverlayAnimationPolicy.shouldAnimate(pulseEnabled: true, reduceMotion: true))
    }
}

private final class BlockingBatteryProvider: BatteryProviding {
    private let lock = NSLock()
    private let statuses: [BatteryStatus]
    private let onInvocation: (Int) -> Void
    private var releases: [Int: DispatchSemaphore] = [:]
    private var activeRequests = 0
    private(set) var invocationCount = 0
    private(set) var maximumConcurrentRequests = 0

    init(statuses: [BatteryStatus], onInvocation: @escaping (Int) -> Void) {
        self.statuses = statuses
        self.onInvocation = onInvocation
    }

    func currentStatus() -> BatteryStatus {
        lock.lock()
        invocationCount += 1
        let invocation = invocationCount
        activeRequests += 1
        maximumConcurrentRequests = max(maximumConcurrentRequests, activeRequests)
        let semaphore = DispatchSemaphore(value: 0)
        releases[invocation] = semaphore
        lock.unlock()

        onInvocation(invocation)
        semaphore.wait()

        lock.lock()
        activeRequests -= 1
        lock.unlock()
        return statuses[min(invocation - 1, statuses.count - 1)]
    }

    func release(invocation: Int) {
        let semaphore: DispatchSemaphore?
        lock.lock()
        semaphore = releases[invocation]
        lock.unlock()
        semaphore?.signal()
    }
}
