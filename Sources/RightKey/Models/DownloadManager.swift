import Foundation

final class DownloadManager {
    func downloadMissing(models: [ModelInfo], onModelStart: ((ModelInfo, Int, Int) -> Void)? = nil) async throws {
        if models.isEmpty { return }
        try FileManager.default.createDirectory(at: ModelStorage.modelsDirectory, withIntermediateDirectories: true)

        for (index, model) in models.enumerated() {
            if model.isDownloaded { continue }
            try removeInvalidLocalFile(for: model)
            onModelStart?(model, index + 1, models.count)
            let request = buildRequest(for: model.downloadURL)
            let (tempURL, response) = try await URLSession.shared.download(for: request)
            try validateResponse(response)
            if FileManager.default.fileExists(atPath: model.localURL.path) {
                try FileManager.default.removeItem(at: model.localURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: model.localURL)
            guard model.isDownloaded else {
                try? FileManager.default.removeItem(at: model.localURL)
                throw DownloadError.invalidSize(modelName: model.name)
            }
        }
    }

    private func buildRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        if let token = runtimeToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func runtimeToken() -> String? {
        let environment = ProcessInfo.processInfo.environment
        let token = environment["HF_TOKEN"] ?? environment["HUGGINGFACE_TOKEN"]
        return token?.isEmpty == false ? token : nil
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw DownloadError.httpStatus(code: http.statusCode)
        }
    }

    private func removeInvalidLocalFile(for model: ModelInfo) throws {
        guard FileManager.default.fileExists(atPath: model.localURL.path) else { return }
        if model.isDownloaded == false {
            try FileManager.default.removeItem(at: model.localURL)
        }
    }
}

enum DownloadError: LocalizedError {
    case httpStatus(code: Int)
    case invalidSize(modelName: String)

    var errorDescription: String? {
        switch self {
        case .httpStatus(let code):
            return "Download failed with status \(code). If the model is gated, set HF_TOKEN."
        case .invalidSize(let modelName):
            return "Downloaded \(modelName) looks incomplete. Check Hugging Face access and retry."
        }
    }
}
