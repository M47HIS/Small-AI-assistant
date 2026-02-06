import Foundation

@MainActor
final class ModelManager: ObservableObject {
    @Published private(set) var activeModelID: String?
    @Published private(set) var isLoading = false
    @Published private(set) var entries: [ModelEntry]

    private let settings: AppSettings
    private let llamaRunner = LlamaRunner()
    private let downloadManager = DownloadManager()
    private let converter = ModelConverter()
    private let contextSize = 2048
    private var idleTimer: Timer?
    private var downloadTasks: [String: Task<Void, Never>] = [:]

    init(settings: AppSettings) {
        self.settings = settings
        self.activeModelID = nil
        self.entries = ModelInfo.available.map { model in
            ModelEntry(info: model, state: model.isDownloaded ? .ready : .notDownloaded, statusMessage: "", errorMessage: nil)
        }
    }

    var models: [ModelInfo] {
        entries.map { $0.info }
    }

    var missingModels: [ModelInfo] {
        entries.filter { $0.state != .ready }.map { $0.info }
    }

    func entry(for id: String) -> ModelEntry? {
        entries.first(where: { $0.info.id == id })
    }

    func selectModel(id: String) {
        if activeModelID != id {
            unloadActiveModel()
        }
        settings.defaultModelID = id
    }

    func downloadModel(id: String) {
        guard let index = entries.firstIndex(where: { $0.info.id == id }) else { return }
        if entries[index].state == .downloading || entries[index].state == .converting {
            return
        }
        let model = entries[index].info
        updateEntry(at: index, state: .downloading, status: "Preparing download...", error: nil)
        let task = Task { @MainActor in
            do {
                try await downloadManager.download(model: model) { [weak self] fileName, current, total in
                    Task { @MainActor in
                        self?.updateEntry(
                            id: model.id,
                            state: .downloading,
                            status: "Downloading \(fileName) (\(current)/\(total))",
                            error: nil
                        )
                    }
                }
                if model.requiresConversion {
                    updateEntry(id: model.id, state: .converting, status: "Converting to GGUF...", error: nil)
                    try await converter.convert(model: model, settings: settings)
                }
                updateEntry(
                    id: model.id,
                    state: model.isDownloaded ? .ready : .notDownloaded,
                    status: model.isDownloaded ? "Ready" : "Download incomplete",
                    error: model.isDownloaded ? nil : "Model file is incomplete."
                )
            } catch {
                updateEntry(id: model.id, state: .error, status: "Error", error: error.localizedDescription)
            }
            downloadTasks[model.id] = nil
        }
        downloadTasks[id] = task
    }

    func deleteModel(id: String) {
        guard let index = entries.firstIndex(where: { $0.info.id == id }) else { return }
        let model = entries[index].info
        try? FileManager.default.removeItem(at: model.outputURL)
        try? FileManager.default.removeItem(at: model.intermediateURL)
        try? FileManager.default.removeItem(at: model.workingDirectory)
        updateEntry(at: index, state: .notDownloaded, status: "Removed", error: nil)
    }

    func streamResponse(prompt: String, context: ContextSnapshot) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task { @MainActor in
                do {
                    let model = try await loadModelIfNeeded()
                    guard let binaryURL = LlamaRuntime.resolveBinaryURL(settings: settings) else {
                        continuation.yield("Llama runtime not found. \(LlamaRuntime.installHint)")
                        continuation.finish()
                        return
                    }

                    let builtPrompt = PromptBuilder.buildPrompt(input: prompt, context: context)
                    let config = LlamaRunner.Config(
                        cliURL: binaryURL,
                        serverURL: LlamaRuntime.resolveServerURL(settings: settings),
                        modelURL: model.outputURL,
                        maxTokens: settings.maxTokens,
                        temperature: settings.temperature,
                        topP: settings.topP,
                        contextSize: contextSize,
                        useServer: settings.useLlamaServer,
                        gpuLayers: settings.gpuLayers
                    )
                    let shouldStream = settings.streamingEnabled
                    let stream = llamaRunner.streamResponse(prompt: builtPrompt, config: config)
                    var fullResponse = ""
                    for await chunk in stream {
                        if shouldStream {
                            continuation.yield(chunk)
                        } else {
                            fullResponse.append(chunk)
                        }
                    }
                    if shouldStream == false {
                        continuation.yield(fullResponse.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    continuation.finish()
                    scheduleIdleUnload()
                } catch {
                    if let managerError = error as? ModelManagerError {
                        continuation.yield(message(for: managerError))
                    } else {
                        continuation.yield("Model error: \(error.localizedDescription)")
                    }
                    continuation.finish()
                }
            }
        }
    }

    private func loadModelIfNeeded() async throws -> ModelInfo {
        let modelID = settings.defaultModelID
        guard let model = ModelInfo.available.first(where: { $0.id == modelID }) else {
            throw ModelManagerError.unknownModel
        }
        guard model.isDownloaded else {
            throw ModelManagerError.modelMissing
        }
        if activeModelID != modelID {
            isLoading = true
            activeModelID = modelID
            isLoading = false
        }
        return model
    }

    private func scheduleIdleUnload() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: settings.idleTimeoutSeconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.unloadActiveModel()
            }
        }
    }

    func unloadActiveModel() {
        idleTimer?.invalidate()
        idleTimer = nil
        activeModelID = nil
        llamaRunner.stopServer()
    }

    private func updateEntry(at index: Int, state: ModelState, status: String, error: String?) {
        entries[index].state = state
        entries[index].statusMessage = status
        entries[index].errorMessage = error
    }

    private func updateEntry(id: String, state: ModelState, status: String, error: String?) {
        guard let index = entries.firstIndex(where: { $0.info.id == id }) else { return }
        updateEntry(at: index, state: state, status: status, error: error)
    }

    private func message(for error: ModelManagerError) -> String {
        switch error {
        case .modelMissing:
            return "Model missing. Download it from Preferences."
        case .unknownModel:
            return "Unknown model selected."
        }
    }
}

struct ModelEntry: Identifiable {
    let info: ModelInfo
    var state: ModelState
    var statusMessage: String
    var errorMessage: String?

    var id: String {
        info.id
    }
}

enum ModelState: String {
    case notDownloaded
    case downloading
    case converting
    case ready
    case error
}

enum ModelManagerError: Error {
    case modelMissing
    case unknownModel
}
