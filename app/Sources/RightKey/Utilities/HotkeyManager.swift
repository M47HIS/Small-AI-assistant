import Cocoa
import Carbon
import Combine

struct KeyCombo: Equatable {
    let keyCode: Int
    let modifiers: NSEvent.ModifierFlags

    var displayString: String {
        let parts = [
            modifiers.contains(.command) ? "Cmd" : nil,
            modifiers.contains(.option) ? "Option" : nil,
            modifiers.contains(.control) ? "Ctrl" : nil,
            modifiers.contains(.shift) ? "Shift" : nil,
            keyLabel
        ].compactMap { $0 }
        return parts.joined(separator: "+")
    }

    private var keyLabel: String {
        if let special = KeyCombo.specialKeyLabels[keyCode] {
            return special
        }
        if let translated = KeyCodeTranslator.shared.label(for: keyCode, modifiers: modifiers) {
            return translated
        }
        return "Key\(keyCode)"
    }

    private static let specialKeyLabels: [Int: String] = [
        36: "Return",
        48: "Tab",
        49: "Space",
        51: "Delete",
        53: "Escape",
        117: "Forward Delete",
        123: "Left",
        124: "Right",
        125: "Down",
        126: "Up",
        122: "F1",
        120: "F2",
        99: "F3",
        118: "F4",
        96: "F5",
        97: "F6",
        98: "F7",
        100: "F8",
        101: "F9",
        109: "F10",
        103: "F11",
        111: "F12"
    ]
}

private final class KeyCodeTranslator {
    static let shared = KeyCodeTranslator()

    func label(for keyCode: Int, modifiers: NSEvent.ModifierFlags) -> String? {
        guard let layoutData = currentLayoutData() else { return nil }
        let translationModifiers = modifiers.intersection([.shift])
        let modifierKeyState = carbonModifierState(from: translationModifiers)
        var deadKeyState: UInt32 = 0
        let maxStringLength = 4
        var actualLength = 0
        var chars = [UniChar](repeating: 0, count: maxStringLength)
        let status = UCKeyTranslate(
            layoutData,
            UInt16(keyCode),
            UInt16(kUCKeyActionDown),
            modifierKeyState,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysMask),
            &deadKeyState,
            maxStringLength,
            &actualLength,
            &chars
        )
        guard status == noErr else { return nil }
        let label = String(utf16CodeUnits: chars, count: actualLength)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard label.isEmpty == false else { return nil }
        return label.uppercased()
    }

    private func carbonModifierState(from modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if modifiers.contains(.shift) {
            carbon |= UInt32(shiftKey)
        }
        return carbon >> 8
    }

    private func currentLayoutData() -> UnsafePointer<UCKeyboardLayout>? {
        guard let inputSource = TISCopyCurrentKeyboardLayoutInputSource()?.takeUnretainedValue() else {
            return nil
        }
        guard let layoutData = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let data = unsafeBitCast(layoutData, to: CFData.self)
        guard let bytes = CFDataGetBytePtr(data) else { return nil }
        return UnsafePointer<UCKeyboardLayout>(OpaquePointer(bytes))
    }
}

final class HotkeyManager {
    var onHotkeyPressed: (() -> Void)?

    private let settings: AppSettings
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var hotkeyMonitor: AnyCancellable?
    private let hotKeyID = EventHotKeyID(signature: OSType(0x524B484B), id: 1)
    private var isListening = false
    private let hotKeyHandler: EventHandlerUPP = { _, event, userData in
        guard let event, let userData else { return noErr }
        let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        manager.handleHotKeyEvent(event)
        return noErr
    }

    init(settings: AppSettings) {
        self.settings = settings
        hotkeyMonitor = settings.$hotkey.sink { [weak self] _ in
            guard let self, self.isListening else { return }
            self.registerHotkey()
        }
    }

    func startListening() {
        isListening = true
        installEventHandlerIfNeeded()
        registerHotkey()
    }

    func stopListening() {
        isListening = false
        unregisterHotkey()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        stopListening()
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetEventDispatcherTarget(),
            hotKeyHandler,
            1,
            &eventSpec,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )
    }

    private func registerHotkey() {
        unregisterHotkey()
        let keyCode = UInt32(settings.hotkey.keyCode)
        let modifiers = carbonModifiers(from: settings.hotkey.modifiers)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        guard status == noErr else { return }
        self.hotKeyRef = hotKeyRef
    }

    private func unregisterHotkey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func handleHotKeyEvent(_ event: EventRef) {
        var pressedHotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &pressedHotKeyID
        )
        guard status == noErr else { return }
        guard pressedHotKeyID.signature == hotKeyID.signature,
              pressedHotKeyID.id == hotKeyID.id else { return }
        onHotkeyPressed?()
    }

    private func carbonModifiers(from modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if modifiers.contains(.command) {
            carbon |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            carbon |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            carbon |= UInt32(controlKey)
        }
        if modifiers.contains(.shift) {
            carbon |= UInt32(shiftKey)
        }
        return carbon
    }
}
