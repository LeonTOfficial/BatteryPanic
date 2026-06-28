import AppKit
import Foundation
import Sparkle

final class AppUpdater: NSObject {
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func wireCheckForUpdatesMenuItem(_ item: NSMenuItem) {
        item.target = updaterController
        item.action = #selector(SPUStandardUpdaterController.checkForUpdates(_:))
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    func checkForUpdatesInBackgroundAfterLaunch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [updaterController] in
            let updater = updaterController.updater
            if updater.automaticallyChecksForUpdates {
                updater.checkForUpdatesInBackground()
            }
        }
    }
}
