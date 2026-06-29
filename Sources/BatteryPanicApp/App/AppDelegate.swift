import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let coordinator = AppCoordinator()
        self.coordinator = coordinator
        coordinator.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        coordinator?.showSettingsForReopen()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
