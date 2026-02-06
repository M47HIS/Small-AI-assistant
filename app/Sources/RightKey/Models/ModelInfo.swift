import Foundation

enum ModelBackend: String {
    case llamaCpp
    case rwkv
}

enum ModelFormat: String {
    case gguf
    case safetensors
}

struct ModelInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let backend: ModelBackend
    let format: ModelFormat
    let hfRepo: String
    let downloadFileName: String
    let outputFileName: String
    let quantization: String
    let license: String
    let tags: [String]
    let sizeBytes: Int64
    let minimumBytes: Int64
    let sourceMinimumBytes: Int64
    let additionalFiles: [String]

    var downloadURL: URL {
        downloadURL(for: downloadFileName)
    }

    var repoURL: URL {
        URL(string: "https://huggingface.co/\(hfRepo)")!
    }

    func downloadURL(for fileName: String) -> URL {
        ModelInfo.hfURL(repo: hfRepo, file: fileName)
    }

    var outputURL: URL {
        ModelStorage.modelsDirectory.appendingPathComponent(outputFileName)
    }

    var workingDirectory: URL {
        ModelStorage.modelsDirectory.appendingPathComponent(id)
    }

    var intermediateURL: URL {
        ModelStorage.modelsDirectory.appendingPathComponent("\(id).f16.gguf")
    }

    var filesToDownload: [String] {
        if format == .gguf {
            return [downloadFileName]
        }
        return [downloadFileName] + additionalFiles
    }

    var isDownloaded: Bool {
        guard let size = outputSize else { return false }
        return size >= minimumBytes
    }

    var outputSize: Int64? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: outputURL.path)
        return attributes?[.size] as? Int64
    }

    var sizeLabel: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    var requiresConversion: Bool {
        format == .safetensors
    }

    static let phi15 = ModelInfo(
        id: "phi-1.5-q4",
        name: "Phi-1.5 Q4",
        backend: .llamaCpp,
        format: .gguf,
        hfRepo: "TheBloke/phi-1_5-GGUF",
        downloadFileName: "phi-1_5.Q4_K_M.gguf",
        outputFileName: "phi-1_5.Q4_K_M.gguf",
        quantization: "Q4_K_M",
        license: "MIT",
        tags: ["code", "chat"],
        sizeBytes: 852_000_000,
        minimumBytes: 600_000_000,
        sourceMinimumBytes: 600_000_000,
        additionalFiles: []
    )

    static let tinyLlama = ModelInfo(
        id: "tinyllama-1.1b-q4",
        name: "TinyLlama 1.1B Q4",
        backend: .llamaCpp,
        format: .gguf,
        hfRepo: "TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF",
        downloadFileName: "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
        outputFileName: "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
        quantization: "Q4_K_M",
        license: "Apache-2.0",
        tags: ["chat", "small"],
        sizeBytes: 700_000_000,
        minimumBytes: 400_000_000,
        sourceMinimumBytes: 400_000_000,
        additionalFiles: []
    )

    static let phi15Base = ModelInfo(
        id: "phi-1.5-hf",
        name: "Phi-1.5 (HF base)",
        backend: .llamaCpp,
        format: .safetensors,
        hfRepo: "microsoft/phi-1_5",
        downloadFileName: "model.safetensors",
        outputFileName: "phi-1_5-converted.Q4_K_M.gguf",
        quantization: "Q4_K_M",
        license: "MIT",
        tags: ["convert", "base"],
        sizeBytes: 2_800_000_000,
        minimumBytes: 600_000_000,
        sourceMinimumBytes: 2_000_000_000,
        additionalFiles: [
            "config.json",
            "tokenizer.json",
            "tokenizer_config.json",
            "special_tokens_map.json",
            "vocab.json",
            "merges.txt",
            "generation_config.json",
            "added_tokens.json"
        ]
    )

    static let available: [ModelInfo] = [phi15, tinyLlama, phi15Base]

    private static func hfURL(repo: String, file: String) -> URL {
        URL(string: "https://huggingface.co/\(repo)/resolve/main/\(file)")!
    }
}

enum ModelStorage {
    static let modelsDirectory: URL = {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let base = appSupport ?? fileManager.homeDirectoryForCurrentUser
        return base
            .appendingPathComponent("RightKey", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
    }()
}
