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
}
