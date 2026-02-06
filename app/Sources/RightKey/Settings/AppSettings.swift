import AppKit
import Foundation

final class AppSettings: ObservableObject {
    @Published var streamingEnabled: Bool {
        didSet { defaults.set(streamingEnabled, forKey: Keys.streamingEnabled) }
    }
    @Published var idleTimeoutSeconds: TimeInterval {
        didSet { defaults.set(idleTimeoutSeconds, forKey: Keys.idleTimeoutSeconds) }
    }
    @Published var defaultModelID: String {
        didSet { defaults.set(defaultModelID, forKey: Keys.defaultModelID) }
    }
    @Published var hotkey: KeyCombo {
        didSet {
            defaults.set(hotkey.keyCode, forKey: Keys.hotkeyCode)
            defaults.set(hotkey.modifiers.rawValue, forKey: Keys.hotkeyModifiers)
        }
    }
    @Published var llamaBinaryPath: String {
        didSet { defaults.set(llamaBinaryPath, forKey: Keys.llamaBinaryPath) }
    }
    @Published var maxTokens: Int {
        didSet { defaults.set(maxTokens, forKey: Keys.maxTokens) }
    }
    @Published var temperature: Double {
        didSet { defaults.set(temperature, forKey: Keys.temperature) }
    }
    @Published var topP: Double {
        didSet { defaults.set(topP, forKey: Keys.topP) }
    }
    @Published var useLlamaServer: Bool {
        didSet { defaults.set(useLlamaServer, forKey: Keys.useLlamaServer) }
    }
    @Published var gpuLayers: Int {
        didSet { defaults.set(gpuLayers, forKey: Keys.gpuLayers) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let streamingValue = defaults.object(forKey: Keys.streamingEnabled) as? Bool
        self.streamingEnabled = streamingValue ?? true

        let timeoutValue = defaults.object(forKey: Keys.idleTimeoutSeconds) as? Double
        self.idleTimeoutSeconds = timeoutValue ?? 90

        self.defaultModelID = defaults.string(forKey: Keys.defaultModelID) ?? ModelInfo.phi15.id

        let storedKeyCode = defaults.object(forKey: Keys.hotkeyCode) as? Int
        let storedModifiersRaw = defaults.object(forKey: Keys.hotkeyModifiers) as? UInt
        if let storedKeyCode, let storedModifiersRaw {
            self.hotkey = KeyCombo(keyCode: storedKeyCode, modifiers: NSEvent.ModifierFlags(rawValue: storedModifiersRaw))
        } else {
            self.hotkey = KeyCombo(keyCode: 49, modifiers: [.option])
        }

        self.llamaBinaryPath = defaults.string(forKey: Keys.llamaBinaryPath) ?? ""
        let storedMaxTokens = defaults.object(forKey: Keys.maxTokens) as? Int
        self.maxTokens = storedMaxTokens ?? 256
        let storedTemperature = defaults.object(forKey: Keys.temperature) as? Double
        self.temperature = storedTemperature ?? 0.7
        let storedTopP = defaults.object(forKey: Keys.topP) as? Double
        self.topP = storedTopP ?? 0.9

        let storedUseServer = defaults.object(forKey: Keys.useLlamaServer) as? Bool
        self.useLlamaServer = storedUseServer ?? true
        let storedGpuLayers = defaults.object(forKey: Keys.gpuLayers) as? Int
        self.gpuLayers = storedGpuLayers ?? 24
    }
}

private enum Keys {
    static let streamingEnabled = "settings.streaming.enabled"
    static let idleTimeoutSeconds = "settings.idle.timeout"
    static let defaultModelID = "settings.model.default"
    static let hotkeyCode = "settings.hotkey.code"
    static let hotkeyModifiers = "settings.hotkey.modifiers"
    static let llamaBinaryPath = "settings.llama.binary"
    static let maxTokens = "settings.generation.maxTokens"
    static let temperature = "settings.generation.temperature"
    static let topP = "settings.generation.topP"
    static let useLlamaServer = "settings.llama.serverEnabled"
    static let gpuLayers = "settings.llama.gpuLayers"
}
