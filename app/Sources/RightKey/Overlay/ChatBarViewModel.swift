import Combine
import Foundation

@MainActor
final class ChatBarViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var responseText = ""
    @Published var isSending = false
    @Published var selectedModelID: String
    @Published var showDownloader = false
    @Published var downloadError: String?
    @Published var downloadStatus = ""
    @Published var isDownloading = false

    private let modelManager: ModelManager
    private let settings: AppSettings
    private var cancellables: Set<AnyCancellable> = []

    init(modelManager: ModelManager, settings: AppSettings) {
        self.modelManager = modelManager
        self.settings = settings
        self.selectedModelID = settings.defaultModelID
        self.showDownloader = modelManager.missingModels.isEmpty == false

        settings.$defaultModelID
            .receive(on: RunLoop.main)
            .sink { [weak self] modelID in
                self?.selectedModelID = modelID
                self?.updateDownloadState()
            }
            .store(in: &cancellables)

        modelManager.$entries
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDownloadState()
            }
            .store(in: &cancellables)

        updateDownloadState()
    }

    var models: [ModelInfo] {
        modelManager.models
    }

    func updateSelectedModel(_ modelID: String) {
        selectedModelID = modelID
        settings.defaultModelID = modelID
        modelManager.selectModel(id: modelID)
    }

    func submit() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        if modelManager.entry(for: selectedModelID)?.state != .ready {
            downloadModelsIfNeeded()
            responseText = "Model is not ready. Downloading now..."
            return
        }
        responseText = ""
        isSending = true
        let context = ContextCollector.capture()
        let stream = modelManager.streamResponse(prompt: trimmed, context: context)
        Task {
            for await token in stream {
                responseText.append(token)
            }
            isSending = false
        }
        inputText = ""
    }

    func downloadModelsIfNeeded() {
        downloadError = nil
        modelManager.downloadModel(id: selectedModelID)
        updateDownloadState()
    }

    private func updateDownloadState() {
        guard let entry = modelManager.entry(for: selectedModelID) else { return }
        switch entry.state {
        case .ready:
            showDownloader = false
            isDownloading = false
            downloadStatus = ""
            downloadError = nil
        case .notDownloaded:
            showDownloader = true
            isDownloading = false
            downloadStatus = "Model not downloaded."
            downloadError = nil
        case .downloading, .converting:
            showDownloader = true
            isDownloading = true
            downloadStatus = entry.statusMessage
            downloadError = nil
        case .error:
            showDownloader = true
            isDownloading = false
            downloadStatus = entry.statusMessage
            downloadError = entry.errorMessage
        }
    }
}
