import AppKit
import Foundation

final class AppSettings: ObservableObject {
    @Published var streamingEnabled: Bool {
        didSet { defaults.set(streamingEnabled, forKey: Keys.streamingEnabled) }
    }
    @Published var idleTimeoutSeconds: TimeInterval {
        didSet {
            let normalized = Self.normalizedIdleTimeout(idleTimeoutSeconds)
            if normalized != idleTimeoutSeconds {
                idleTimeoutSeconds = normalized
                return
            }
            defaults.set(idleTimeoutSeconds, forKey: Keys.idleTimeoutSeconds)
        }
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
        didSet {
            let normalized = Self.normalizedPathString(llamaBinaryPath)
            if normalized != llamaBinaryPath {
                llamaBinaryPath = normalized
                return
            }
            defaults.set(llamaBinaryPath, forKey: Keys.llamaBinaryPath)
        }
    }
    @Published var maxTokens: Int {
        didSet {
            let normalized = Self.normalizedMaxTokens(maxTokens)
            if normalized != maxTokens {
                maxTokens = normalized
                return
            }
            defaults.set(maxTokens, forKey: Keys.maxTokens)
        }
    }
    @Published var temperature: Double {
        didSet {
            let normalized = Self.normalizedTemperature(temperature)
            if normalized != temperature {
                temperature = normalized
                return
            }
            defaults.set(temperature, forKey: Keys.temperature)
        }
    }
    @Published var topP: Double {
        didSet {
            let normalized = Self.normalizedTopP(topP)
            if normalized != topP {
                topP = normalized
                return
            }
            defaults.set(topP, forKey: Keys.topP)
        }
    }
    @Published var useLlamaServer: Bool {
        didSet { defaults.set(useLlamaServer, forKey: Keys.useLlamaServer) }
    }
    @Published var gpuLayers: Int {
        didSet {
            let normalized = Self.normalizedGpuLayers(gpuLayers)
            if normalized != gpuLayers {
                gpuLayers = normalized
                return
            }
            defaults.set(gpuLayers, forKey: Keys.gpuLayers)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let streamingValue = defaults.object(forKey: Keys.streamingEnabled) as? Bool
        self.streamingEnabled = streamingValue ?? true

        let timeoutValue = defaults.object(forKey: Keys.idleTimeoutSeconds) as? Double
        self.idleTimeoutSeconds = Self.normalizedIdleTimeout(timeoutValue ?? 90)

        let fallbackModelID = ModelInfo.phi15.id
        if let storedModelID = defaults.string(forKey: Keys.defaultModelID),
           ModelInfo.available.contains(where: { $0.id == storedModelID }) {
            self.defaultModelID = storedModelID
        } else {
            self.defaultModelID = fallbackModelID
            defaults.set(fallbackModelID, forKey: Keys.defaultModelID)
        }

        let storedKeyCode = defaults.object(forKey: Keys.hotkeyCode) as? Int
        let storedModifiersRaw = defaults.object(forKey: Keys.hotkeyModifiers) as? UInt
        if let storedKeyCode, let storedModifiersRaw {
            self.hotkey = KeyCombo(keyCode: storedKeyCode, modifiers: NSEvent.ModifierFlags(rawValue: storedModifiersRaw))
        } else {
            self.hotkey = KeyCombo(keyCode: 49, modifiers: [.option])
        }

        self.llamaBinaryPath = Self.normalizedPathString(defaults.string(forKey: Keys.llamaBinaryPath) ?? "")
        let storedMaxTokens = defaults.object(forKey: Keys.maxTokens) as? Int
        self.maxTokens = Self.normalizedMaxTokens(storedMaxTokens ?? 256)
        let storedTemperature = defaults.object(forKey: Keys.temperature) as? Double
        self.temperature = Self.normalizedTemperature(storedTemperature ?? 0.7)
        let storedTopP = defaults.object(forKey: Keys.topP) as? Double
        self.topP = Self.normalizedTopP(storedTopP ?? 0.9)

        let storedUseServer = defaults.object(forKey: Keys.useLlamaServer) as? Bool
        self.useLlamaServer = storedUseServer ?? true
        let storedGpuLayers = defaults.object(forKey: Keys.gpuLayers) as? Int
        self.gpuLayers = Self.normalizedGpuLayers(storedGpuLayers ?? 24)
    }

    private static func normalizedIdleTimeout(_ value: TimeInterval) -> TimeInterval {
        value.clamped(to: 30...300)
    }

    private static func normalizedPathString(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return "" }
        return (trimmed as NSString).expandingTildeInPath
    }

    private static func normalizedMaxTokens(_ value: Int) -> Int {
        value.clamped(to: 64...1024)
    }

    private static func normalizedTemperature(_ value: Double) -> Double {
        value.clamped(to: 0.0...1.5)
    }

    private static func normalizedTopP(_ value: Double) -> Double {
        value.clamped(to: 0.1...1.0)
    }

    private static func normalizedGpuLayers(_ value: Int) -> Int {
        value.clamped(to: 0...64)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
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
