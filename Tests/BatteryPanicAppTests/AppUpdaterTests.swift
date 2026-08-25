import Foundation
import XCTest
@testable import BatteryPanicApp

@MainActor
final class AppUpdaterTests: XCTestCase {
    func testLaunchAlwaysUsesSilentInformationProbe() {
        let driver = UpdateDriverSpy()
        let updater = makeUpdater(driver: driver)

        updater.checkQuietlyAfterLaunch()

        XCTAssertEqual(driver.informationCheckCount, 1)
        XCTAssertEqual(driver.foregroundCheckCount, 0)
        XCTAssertEqual(updater.activeAutomaticTriggerForTesting, .launch)
    }

    func testLaunchDoesNotInterruptAnExistingSession() {
        let driver = UpdateDriverSpy()
        driver.sessionInProgress = true
        let updater = makeUpdater(driver: driver)

        updater.checkQuietlyAfterLaunch()

        XCTAssertEqual(driver.informationCheckCount, 0)
        XCTAssertNil(updater.activeAutomaticTriggerForTesting)
    }

    func testScheduledAutomaticTriggerUsesTheSameSilentProbe() {
        let driver = UpdateDriverSpy()
        let updater = makeUpdater(driver: driver)

        updater.checkQuietlyAutomatically()

        XCTAssertEqual(driver.informationCheckCount, 1)
        XCTAssertEqual(driver.foregroundCheckCount, 0)
        XCTAssertEqual(updater.activeAutomaticTriggerForTesting, .automatic)
    }

    func testReopenWithoutUpdateRemainsSilent() {
        let driver = UpdateDriverSpy()
        var activationCount = 0
        let updater = makeUpdater(driver: driver) {
            activationCount += 1
        }

        updater.checkQuietlyAfterReopen()
        updater.finishUpdateCycle(error: nil)

        XCTAssertEqual(driver.informationCheckCount, 1)
        XCTAssertEqual(driver.foregroundCheckCount, 0)
        XCTAssertEqual(activationCount, 0)
        XCTAssertNil(updater.activeAutomaticTriggerForTesting)
    }

    func testFoundUpdateIsPresentedOnceAfterSilentProbeFinishes() {
        let driver = UpdateDriverSpy()
        var activationCount = 0
        let updater = makeUpdater(driver: driver) {
            activationCount += 1
        }

        updater.checkQuietlyAfterReopen()
        updater.noteAutomaticUpdateFound()
        updater.finishUpdateCycle(error: nil)
        updater.finishUpdateCycle(error: nil)

        XCTAssertEqual(driver.informationCheckCount, 1)
        XCTAssertEqual(driver.foregroundCheckCount, 1)
        XCTAssertEqual(activationCount, 1)
    }

    func testFoundUpdateWaitsUntilTheProbeSessionHasClosed() {
        let driver = UpdateDriverSpy()
        var scheduledPresentations: [() -> Void] = []
        var activationCount = 0
        let updater = AppUpdater(
            updater: driver,
            activateApplication: { activationCount += 1 },
            schedulePresentation: { scheduledPresentations.append($0) }
        )

        updater.checkQuietlyAfterLaunch()
        updater.noteAutomaticUpdateFound()
        driver.sessionInProgress = true
        updater.finishUpdateCycle(error: nil)

        XCTAssertEqual(scheduledPresentations.count, 1)
        scheduledPresentations.removeFirst()()
        XCTAssertEqual(driver.foregroundCheckCount, 0)
        XCTAssertEqual(scheduledPresentations.count, 1)

        driver.sessionInProgress = false
        scheduledPresentations.removeFirst()()

        XCTAssertEqual(driver.foregroundCheckCount, 1)
        XCTAssertEqual(activationCount, 1)
    }

    func testProbeErrorNeverPresentsUpdate() {
        let driver = UpdateDriverSpy()
        var activationCount = 0
        let updater = makeUpdater(driver: driver) {
            activationCount += 1
        }

        updater.checkQuietlyAfterLaunch()
        updater.noteAutomaticUpdateFound()
        updater.finishUpdateCycle(
            error: NSError(domain: "AppUpdaterTests", code: 7)
        )

        XCTAssertEqual(driver.foregroundCheckCount, 0)
        XCTAssertEqual(activationCount, 0)
    }

    func testRepeatedReopenDoesNotStartOverlappingProbe() {
        let driver = UpdateDriverSpy()
        let updater = makeUpdater(driver: driver)

        updater.checkQuietlyAfterReopen()
        updater.checkQuietlyAfterReopen()

        XCTAssertEqual(driver.informationCheckCount, 1)
        XCTAssertEqual(updater.activeAutomaticTriggerForTesting, .reopen)
    }

    func testReopenFocusesAnExistingUpdateSession() {
        let driver = UpdateDriverSpy()
        driver.sessionInProgress = true
        var activationCount = 0
        let updater = makeUpdater(driver: driver) {
            activationCount += 1
        }

        updater.checkQuietlyAfterReopen()

        XCTAssertEqual(driver.informationCheckCount, 0)
        XCTAssertEqual(driver.foregroundCheckCount, 1)
        XCTAssertEqual(activationCount, 1)
    }

    func testManualCheckRemainsForegroundAndCancelsPendingAutomaticIntent() {
        let driver = UpdateDriverSpy()
        let updater = makeUpdater(driver: driver)
        updater.checkQuietlyAfterLaunch()

        updater.checkForUpdates()

        XCTAssertEqual(driver.foregroundCheckCount, 1)
        XCTAssertNil(updater.activeAutomaticTriggerForTesting)
    }

    private func makeUpdater(
        driver: UpdateDriverSpy,
        activateApplication: @escaping () -> Void = {}
    ) -> AppUpdater {
        AppUpdater(
            updater: driver,
            activateApplication: activateApplication,
            schedulePresentation: { $0() }
        )
    }
}

private final class UpdateDriverSpy: AppUpdateChecking {
    var sessionInProgress = false
    private(set) var foregroundCheckCount = 0
    private(set) var informationCheckCount = 0

    func checkForUpdates() {
        foregroundCheckCount += 1
    }

    func checkForUpdateInformation() {
        informationCheckCount += 1
    }
}
