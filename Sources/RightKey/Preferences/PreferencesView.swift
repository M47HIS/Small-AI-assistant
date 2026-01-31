import AppKit
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: AppSettings
    @State private var isRecording = false
    @State private var recordingHint = "Press Record, then type the new shortcut."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                hotkeyGroup
                behaviorGroup
                modelGroup
                Spacer()
            }
            .padding(28)
        }
        .frame(minWidth: 620, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDisappear {
            stopRecording()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.accentColor)
                .padding(10)
                .background(Circle().fill(Color(nsColor: .controlBackgroundColor)))
            VStack(alignment: .leading, spacing: 4) {
                Text("Preferences")
                    .font(.custom("Avenir Next Demi Bold", size: 22))
                Text("Hotkeys, streaming, and default model")
                    .font(.custom("Avenir Next", size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var hotkeyGroup: some View {
        preferenceSection(title: "Hotkey", subtitle: "Set the global shortcut to open RightKey.", systemImage: "keyboard") {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current shortcut")
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundColor(.secondary)
                    Text(settings.hotkey.displayString)
                        .font(.custom("Avenir Next Demi Bold", size: 14))
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        toggleRecording()
                    } label: {
                        Text(isRecording ? "Recording…" : "Record Shortcut")
                            .font(.custom("Avenir Next Demi Bold", size: 12))
                    }
                    .buttonStyle(.borderedProminent)

                    if isRecording {
                        Button("Cancel") {
                            stopRecording()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Text(recordingHint)
                .font(.custom("Avenir Next", size: 12))
                .foregroundColor(.secondary)

            if isRecording {
                KeyCaptureView(onKeyDown: handleRecorded)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
            }
        }
    }

    private var behaviorGroup: some View {
        preferenceSection(title: "Behavior", subtitle: "Streaming and idle unloading.", systemImage: "gearshape") {
            Toggle("Stream tokens", isOn: $settings.streamingEnabled)

            VStack(alignment: .leading, spacing: 6) {
                Text("Idle unload")
                    .font(.custom("Avenir Next", size: 12))
                    .foregroundColor(.secondary)
                Stepper(value: $settings.idleTimeoutSeconds, in: 30...300, step: 10) {
                    Text("\(Int(settings.idleTimeoutSeconds)) seconds")
                        .font(.custom("Avenir Next Demi Bold", size: 12))
                }
            }
        }
    }

    private var modelGroup: some View {
        preferenceSection(title: "Models", subtitle: "Choose the default model and storage path.", systemImage: "cube") {
            Picker("Default model", selection: $settings.defaultModelID) {
                ForEach(ModelInfo.available) { model in
                    Text(model.name).tag(model.id)
                }
            }
            .pickerStyle(.menu)

            HStack {
                Text("Models stored at")
                    .font(.custom("Avenir Next", size: 12))
                    .foregroundColor(.secondary)
                Spacer()
                Text(ModelStorage.modelsDirectory.path)
                    .font(.custom("Avenir Next Demi Bold", size: 12))
            }
        }
    }

    private func preferenceSection<Content: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(nsColor: .controlBackgroundColor)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Avenir Next Demi Bold", size: 16))
                    Text(subtitle)
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
            )
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        recordingHint = "Press the new shortcut now."
    }

    private func stopRecording(resetHint: Bool = true) {
        isRecording = false
        if resetHint {
            recordingHint = "Press Record, then type the new shortcut."
        }
    }

    private func handleRecorded(_ event: NSEvent) {
        guard isRecording else { return }
        guard isModifierKeyCode(Int(event.keyCode)) == false else { return }
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if modifiers.isEmpty {
            recordingHint = "Include at least one modifier (Cmd/Option/Ctrl/Shift)."
            return
        }
        if event.keyCode == 53 {
            stopRecording()
            recordingHint = "Recording cancelled."
            return
        }
        DispatchQueue.main.async {
            let combo = KeyCombo(keyCode: Int(event.keyCode), modifiers: modifiers)
            settings.hotkey = combo
            recordingHint = "Recorded: \(combo.displayString)"
            stopRecording(resetHint: false)
        }
    }

    private func isModifierKeyCode(_ keyCode: Int) -> Bool {
        switch keyCode {
        case 54, 55, 56, 57, 58, 59, 60, 61, 62:
            return true
        default:
            return false
        }
    }
}

private struct KeyCaptureView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Void

    func makeNSView(context: Context) -> KeyCaptureNSView {
        KeyCaptureNSView(onKeyDown: onKeyDown)
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

private final class KeyCaptureNSView: NSView {
    private let onKeyDown: (NSEvent) -> Void

    init(onKeyDown: @escaping (NSEvent) -> Void) {
        self.onKeyDown = onKeyDown
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        onKeyDown(event)
    }
}
