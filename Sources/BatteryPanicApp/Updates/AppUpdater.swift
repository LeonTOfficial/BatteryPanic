import AppKit
import Foundation
import OSLog
import Sparkle

enum AppUpdateCheckTrigger: Equatable {
    case launch
    case reopen
    case automatic
    case manual
}

protocol AppUpdateChecking: AnyObject {
    var sessionInProgress: Bool { get }

    func checkForUpdates()
    func checkForUpdateInformation()
}

extension SPUUpdater: AppUpdateChecking {}

final class AppUpdater: NSObject, SPUUpdaterDelegate {
    /// `SUNoUpdateError` from Sparkle's public `SUErrors.h` is not imported
    /// into Swift as a named symbol.
    private static let noUpdateErrorCode = 1001
    private static let logger = Logger(
        subsystem: "com.leontofficial.batterypanic.mac",
        category: "updates"
    )

    private let injectedUpdater: (any AppUpdateChecking)?
    private let activateApplication: () -> Void
    private let schedulePresentation: (@escaping () -> Void) -> Void
    private var activeAutomaticTrigger: AppUpdateCheckTrigger?
    private var automaticCheckFoundUpdate = false
    private var isAutomaticPresentationPending = false

    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: self,
        userDriverDelegate: nil
    )

    private var updater: any AppUpdateChecking {
        injectedUpdater ?? updaterController.updater
    }

    init(
        updater: (any AppUpdateChecking)? = nil,
        activateApplication: @escaping () -> Void = {
            if #available(macOS 14.0, *) {
                NSApplication.shared.activate()
            } else {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        },
        schedulePresentation: @escaping (@escaping () -> Void) -> Void = { presentation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                presentation()
            }
        }
    ) {
        injectedUpdater = updater
        self.activateApplication = activateApplication
        self.schedulePresentation = schedulePresentation
        super.init()
    }

    func wireCheckForUpdatesMenuItem(_ item: NSMenuItem) {
        item.target = self
        item.action = #selector(checkForUpdatesFromMenu)
    }

    func checkForUpdates() {
        isAutomaticPresentationPending = false
        beginCheck(trigger: .manual)
    }

    func checkQuietlyAfterLaunch() {
        beginCheck(trigger: .launch)
    }

    func checkQuietlyAfterReopen() {
        beginCheck(trigger: .reopen)
    }

    func checkQuietlyAutomatically() {
        beginCheck(trigger: .automatic)
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        noteAutomaticUpdateFound()
    }

    func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck,
        error: (any Error)?
    ) {
        finishUpdateCycle(error: error)
    }

    func noteAutomaticUpdateFound() {
        guard activeAutomaticTrigger != nil else { return }
        automaticCheckFoundUpdate = true
    }

    func finishUpdateCycle(error: (any Error)?) {
        let trigger = activeAutomaticTrigger
        let shouldPresentUpdate = trigger != nil
            && automaticCheckFoundUpdate
            && error == nil

        activeAutomaticTrigger = nil
        automaticCheckFoundUpdate = false

        if let error {
            let updateError = error as NSError
            if updateError.code == Self.noUpdateErrorCode {
                Self.logger.debug("Sparkle update cycle found no newer version")
            } else {
                Self.logger.error(
                    "Sparkle update cycle failed in \(updateError.domain, privacy: .public) with code \(updateError.code, privacy: .public)"
                )
            }
        } else {
            Self.logger.debug("Sparkle update cycle finished successfully")
        }

        guard shouldPresentUpdate else { return }
        isAutomaticPresentationPending = true
        presentFoundUpdateWhenReady(attemptsRemaining: 40)
    }

    private func presentFoundUpdateWhenReady(attemptsRemaining: Int) {
        schedulePresentation { [weak self] in
            guard let self else { return }
            guard self.isAutomaticPresentationPending else { return }
            guard !self.updater.sessionInProgress else {
                guard attemptsRemaining > 1 else {
                    self.isAutomaticPresentationPending = false
                    Self.logger.error("Sparkle update window could not be presented after the probe finished")
                    return
                }
                self.presentFoundUpdateWhenReady(attemptsRemaining: attemptsRemaining - 1)
                return
            }

            self.isAutomaticPresentationPending = false
            self.activateApplication()
            self.updater.checkForUpdates()
        }
    }

    var activeAutomaticTriggerForTesting: AppUpdateCheckTrigger? {
        activeAutomaticTrigger
    }

    private func beginCheck(trigger: AppUpdateCheckTrigger) {
        if trigger == .manual {
            activeAutomaticTrigger = nil
            automaticCheckFoundUpdate = false
            updater.checkForUpdates()
            return
        }

        guard activeAutomaticTrigger == nil, !isAutomaticPresentationPending else { return }

        if trigger == .reopen, updater.sessionInProgress {
            activateApplication()
            updater.checkForUpdates()
            return
        }

        guard !updater.sessionInProgress else { return }

        activeAutomaticTrigger = trigger
        automaticCheckFoundUpdate = false
        updater.checkForUpdateInformation()
    }

    @objc private func checkForUpdatesFromMenu(_ sender: Any?) {
        checkForUpdates()
    }
}
