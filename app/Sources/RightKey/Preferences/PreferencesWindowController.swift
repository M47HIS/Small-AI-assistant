import Cocoa
import SwiftUI

final class PreferencesWindowController {
    private let settings: AppSettings
    private let modelManager: ModelManager
    private var window: NSWindow?

    init(settings: AppSettings, modelManager: ModelManager) {
        self.settings = settings
        self.modelManager = modelManager
    }

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = PreferencesView(settings: settings, modelManager: modelManager)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.tabbingMode = .disallowed
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.isReleasedWhenClosed = false
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
