import Foundation

final class DownloadManager {
    func download(model: ModelInfo, onFileStart: ((String, Int, Int) -> Void)? = nil) async throws {
        try FileManager.default.createDirectory(at: ModelStorage.modelsDirectory, withIntermediateDirectories: true)
        if model.format == .gguf {
            try removeInvalidOutputFile(for: model)
            onFileStart?(model.downloadFileName, 1, 1)
            let destination = model.outputURL
            try await downloadFile(from: model.downloadURL, to: destination)
            try validateFileSize(at: destination, minimumBytes: model.minimumBytes, modelName: model.name)
            return
        }

        try prepareWorkingDirectory(for: model)
        let files = model.filesToDownload
        for (index, fileName) in files.enumerated() {
            onFileStart?(fileName, index + 1, files.count)
            let destination = model.workingDirectory.appendingPathComponent(fileName)
            try await downloadFile(from: model.downloadURL(for: fileName), to: destination)
            if fileName == model.downloadFileName {
                try validateFileSize(at: destination, minimumBytes: model.sourceMinimumBytes, modelName: model.name)
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

    private func prepareWorkingDirectory(for model: ModelInfo) throws {
        let directory = model.workingDirectory
        if FileManager.default.fileExists(atPath: directory.path) == false {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return
        }
        let modelFile = directory.appendingPathComponent(model.downloadFileName)
        if validateFileSize(at: modelFile, minimumBytes: model.sourceMinimumBytes) == false {
            try FileManager.default.removeItem(at: directory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    private func removeInvalidOutputFile(for model: ModelInfo) throws {
        guard FileManager.default.fileExists(atPath: model.outputURL.path) else { return }
        if model.isDownloaded == false {
            try FileManager.default.removeItem(at: model.outputURL)
        }
    }

    private func downloadFile(from url: URL, to destination: URL) async throws {
        let request = buildRequest(for: url)
        let (tempURL, response) = try await URLSession.shared.download(for: request)
        try validateResponse(response)
        let destinationDirectory = destination.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
    }

    private func validateFileSize(at url: URL, minimumBytes: Int64, modelName: String? = nil) throws {
        guard validateFileSize(at: url, minimumBytes: minimumBytes) else {
            let name = modelName ?? url.lastPathComponent
            throw DownloadError.invalidSize(modelName: name)
        }
    }

    private func validateFileSize(at url: URL, minimumBytes: Int64) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else { return false }
        return size >= minimumBytes
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
