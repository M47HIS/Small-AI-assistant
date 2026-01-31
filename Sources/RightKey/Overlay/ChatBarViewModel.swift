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
    private let downloadManager = DownloadManager()
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
            }
            .store(in: &cancellables)
    }

    var models: [ModelInfo] {
        ModelInfo.available
    }

    func updateSelectedModel(_ modelID: String) {
        selectedModelID = modelID
        settings.defaultModelID = modelID
        modelManager.selectModel(id: modelID)
    }

    func submit() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        if modelManager.missingModels.isEmpty == false {
            downloadModelsIfNeeded()
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
        showDownloader = true
        isDownloading = true
        downloadStatus = "Preparing download..."
        let missingModels = modelManager.missingModels
        Task {
            do {
                try await downloadManager.downloadMissing(models: missingModels) { [weak self] model, index, total in
                    Task { @MainActor in
                        self?.downloadStatus = "Downloading \(model.name) (\(index)/\(total))"
                    }
                }
                showDownloader = modelManager.missingModels.isEmpty == false
                isDownloading = false
                downloadStatus = showDownloader ? "Waiting for download..." : "Download complete."
            } catch {
                isDownloading = false
                downloadStatus = "Download failed."
                downloadError = error.localizedDescription
            }
        }
    }
}
