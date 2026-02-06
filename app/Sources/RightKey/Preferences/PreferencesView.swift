import AppKit
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var modelManager: ModelManager
    @State private var isRecording = false
    @State private var recordingHint = "Press Record, then type the new shortcut."
    @State private var keyMonitor: Any?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                hotkeyGroup
                behaviorGroup
                runtimeGroup
                generationGroup
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
        preferenceSection(title: "Models", subtitle: "Download and select models.", systemImage: "cube") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(modelManager.entries) { entry in
                    modelRow(entry)
                }
            }

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

    private var runtimeGroup: some View {
        preferenceSection(title: "Runtime", subtitle: "Set the llama.cpp binary if it is not auto-detected.", systemImage: "terminal") {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Llama binary")
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundColor(.secondary)
                    Text(settings.llamaBinaryPath.isEmpty ? "Auto-detect (brew/LLAMA_BIN)" : settings.llamaBinaryPath)
                        .font(.custom("Avenir Next Demi Bold", size: 12))
                        .lineLimit(2)
                }
                Spacer()
                Button("Choose") {
                    chooseLlamaBinary()
                }
                .buttonStyle(.borderedProminent)

                Button("Clear") {
                    settings.llamaBinaryPath = ""
                }
                .buttonStyle(.bordered)
            }

            Toggle("Use persistent server", isOn: $settings.useLlamaServer)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("GPU layers")
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(settings.gpuLayers)")
                        .font(.custom("Avenir Next Demi Bold", size: 12))
                }
                Stepper(value: $settings.gpuLayers, in: 0...64, step: 1) {
                    Text(settings.gpuLayers == 0 ? "CPU only" : "\(settings.gpuLayers) layers")
                        .font(.custom("Avenir Next Demi Bold", size: 12))
                }
            }
        }
    }

    private var generationGroup: some View {
        preferenceSection(title: "Generation", subtitle: "Tune decoding for Phi-1.5.", systemImage: "dial.high") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Max tokens")
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(settings.maxTokens)")
                        .font(.custom("Avenir Next Demi Bold", size: 12))
                }
                Stepper(value: $settings.maxTokens, in: 64...1024, step: 32) {
                    Text("\(settings.maxTokens) tokens")
                        .font(.custom("Avenir Next Demi Bold", size: 12))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Temperature")
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", settings.temperature))
                        .font(.custom("Avenir Next Demi Bold", size: 12))
                }
                Slider(value: $settings.temperature, in: 0.0...1.5, step: 0.05)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Top P")
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", settings.topP))
                        .font(.custom("Avenir Next Demi Bold", size: 12))
                }
                Slider(value: $settings.topP, in: 0.1...1.0, step: 0.05)
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

    private func modelRow(_ entry: ModelEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.info.name)
                        .font(.custom("Avenir Next Demi Bold", size: 13))
                    Text("\(entry.info.sizeLabel) · \(entry.info.quantization)")
                        .font(.custom("Avenir Next", size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(statusLabel(for: entry))
                    .font(.custom("Avenir Next", size: 11))
                    .foregroundColor(statusColor(for: entry))
            }

            HStack(spacing: 8) {
                if entry.info.id != settings.defaultModelID, entry.state == .ready {
                    Button("Use") {
                        settings.defaultModelID = entry.info.id
                        modelManager.selectModel(id: entry.info.id)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if entry.state == .notDownloaded || entry.state == .error {
                    Button("Download") {
                        modelManager.downloadModel(id: entry.info.id)
                    }
                    .buttonStyle(.bordered)
                }

                if entry.state == .ready {
                    Button("Delete") {
                        modelManager.deleteModel(id: entry.info.id)
                    }
                    .buttonStyle(.bordered)
                }

                if entry.info.id == settings.defaultModelID {
                    Text("Selected")
                        .font(.custom("Avenir Next", size: 11))
                        .foregroundColor(.secondary)
                }
            }

            if entry.state == .downloading || entry.state == .converting {
                Text(entry.statusMessage)
                    .font(.custom("Avenir Next", size: 11))
                    .foregroundColor(.secondary)
            }

            if let error = entry.errorMessage, entry.state == .error {
                Text(error)
                    .font(.custom("Avenir Next", size: 11))
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
        )
    }

    private func statusLabel(for entry: ModelEntry) -> String {
        switch entry.state {
        case .ready:
            return "Ready"
        case .notDownloaded:
            return "Not downloaded"
        case .downloading:
            return "Downloading"
        case .converting:
            return "Converting"
        case .error:
            return "Error"
        }
    }

    private func statusColor(for entry: ModelEntry) -> Color {
        switch entry.state {
        case .ready:
            return .green
        case .error:
            return .red
        case .downloading, .converting:
            return .orange
        case .notDownloaded:
            return .secondary
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
        startKeyMonitorIfNeeded()
    }

    private func stopRecording(resetHint: Bool = true) {
        isRecording = false
        if resetHint {
            recordingHint = "Press Record, then type the new shortcut."
        }
        stopKeyMonitorIfNeeded()
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

    private func chooseLlamaBinary() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Choose"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            settings.llamaBinaryPath = url.path
        }
    }

    private func startKeyMonitorIfNeeded() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleRecorded(event)
            return nil
        }
    }

    private func stopKeyMonitorIfNeeded() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
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
