import Foundation

@MainActor
final class ModelManager: ObservableObject {
    @Published private(set) var activeModelID: String?
    @Published private(set) var isLoading = false

    private let settings: AppSettings
    private let llamaRunner = LlamaRunner()
    private let contextSize = 2048
    private var idleTimer: Timer?

    init(settings: AppSettings) {
        self.settings = settings
        self.activeModelID = nil
    }

    var missingModels: [ModelInfo] {
        ModelInfo.available.filter { $0.isDownloaded == false }
    }

    func selectModel(id: String) {
        if activeModelID != id {
            unloadActiveModel()
        }
        settings.defaultModelID = id
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
                        binaryURL: binaryURL,
                        modelURL: model.localURL,
                        maxTokens: settings.maxTokens,
                        temperature: settings.temperature,
                        topP: settings.topP,
                        contextSize: contextSize
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
    }

    private func message(for error: ModelManagerError) -> String {
        switch error {
        case .modelMissing:
            return "Model missing. Download it from the chat bar first."
        case .unknownModel:
            return "Unknown model selected."
        }
    }
}

enum ModelManagerError: Error {
    case modelMissing
    case unknownModel
}
