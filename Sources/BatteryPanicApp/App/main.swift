import AppKit

private let appDelegate = AppDelegate()

let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.delegate = appDelegate
app.run()
