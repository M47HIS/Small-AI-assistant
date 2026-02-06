import Foundation

@MainActor
final class AppState: ObservableObject {
    let settings: AppSettings
    let modelManager: ModelManager
    let overlayController: OverlayWindowController
    let preferencesController: PreferencesWindowController
    private let hotkeyManager: HotkeyManager

    init() {
        self.settings = AppSettings()
        self.modelManager = ModelManager(settings: settings)
        self.preferencesController = PreferencesWindowController(settings: settings, modelManager: modelManager)
        self.overlayController = OverlayWindowController(
            modelManager: modelManager,
            settings: settings,
            onOpenPreferences: { [weak preferencesController] in
                preferencesController?.show()
            }
        )
        self.hotkeyManager = HotkeyManager(settings: settings)

        hotkeyManager.onHotkeyPressed = { [weak overlayController] in
            overlayController?.toggle()
        }
        hotkeyManager.startListening()
    }
}
