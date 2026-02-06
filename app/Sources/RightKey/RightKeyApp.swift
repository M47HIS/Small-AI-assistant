import AppKit
import SwiftUI

@main
struct RightKeyApp: App {
    @StateObject private var appState = AppState()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        UserDefaults.standard.set(false, forKey: "NSWindowSupportsAutomaticTabbing")
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        MenuBarExtra("RightKey", systemImage: "sparkle") {
            Button("Toggle Chat Bar") {
                appState.overlayController.toggle()
            }
            Button("Preferences") {
                appState.preferencesController.show()
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.menu)
    }
}
