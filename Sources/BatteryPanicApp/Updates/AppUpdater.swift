import AppKit
import Foundation
import OSLog
import Sparkle

final class AppUpdater: NSObject, SPUUpdaterDelegate {
    private static let logger = Logger(
        subsystem: "com.leontofficial.batterypanic.mac",
        category: "updates"
    )

    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: self,
        userDriverDelegate: nil
    )

    func wireCheckForUpdatesMenuItem(_ item: NSMenuItem) {
        item.target = self
        item.action = #selector(checkForUpdatesFromMenu)
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    func checkForUpdatesInBackgroundAfterLaunch() {
        // Sparkle only recommends a forced launch check immediately after the
        // updater starts. Later checks are left to its daily scheduler.
        let updater = updaterController.updater
        DispatchQueue.main.async { [weak updater] in
            guard let updater, updater.automaticallyChecksForUpdates else { return }
            updater.checkForUpdatesInBackground()
        }
    }

    func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck,
        error: (any Error)?
    ) {
        if let error {
            let updateError = error as NSError
            Self.logger.error(
                "Sparkle update cycle failed in \(updateError.domain, privacy: .public) with code \(updateError.code, privacy: .public)"
            )
        } else {
            Self.logger.debug("Sparkle update cycle finished successfully")
        }
    }

    @objc private func checkForUpdatesFromMenu(_ sender: Any?) {
        checkForUpdates()
    }
}
