import AppKit
import Foundation
import Sparkle

final class AppUpdater: NSObject {
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
            guard let self else { return }
            let updater = updaterController.updater
            if updater.automaticallyChecksForUpdates {
                updater.checkForUpdatesInBackground()
            }
        }
    }

    @objc private func checkForUpdatesFromMenu(_ sender: Any?) {
        checkForUpdates()
    }
}
