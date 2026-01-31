import Foundation

enum ModelBackend: String {
    case llamaCpp
    case rwkv
}

struct ModelInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let backend: ModelBackend
    let downloadURL: URL
    let fileName: String
    let minimumBytes: Int64

    var localURL: URL {
        ModelStorage.modelsDirectory.appendingPathComponent(fileName)
    }

    var isDownloaded: Bool {
        guard let size = fileSize else { return false }
        return size >= minimumBytes
    }

    private var fileSize: Int64? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: localURL.path)
        return attributes?[.size] as? Int64
    }

    static let phi15 = ModelInfo(
        id: "phi-1.5-q4",
        name: "Phi-1.5 Q4",
        backend: .llamaCpp,
        downloadURL: URL(string: "https://huggingface.co/TheBloke/phi-1_5-GGUF/resolve/main/phi-1_5.Q4_K_M.gguf")!,
        fileName: "phi-1_5.Q4_K_M.gguf",
        minimumBytes: 100_000_000
    )

    static let rwkv430 = ModelInfo(
        id: "rwkv-430m",
        name: "RWKV 430M",
        backend: .rwkv,
        downloadURL: URL(string: "https://huggingface.co/RWKV/rwkv-4-pile-430m/resolve/main/RWKV-4-Pile-430M-20220808-8066.pth")!,
        fileName: "RWKV-4-Pile-430M-20220808-8066.pth",
        minimumBytes: 100_000_000
    )

    static let available: [ModelInfo] = [phi15]
}

enum ModelStorage {
    static let modelsDirectory = URL(fileURLWithPath: "/Users/mathis.naud/Desktop/DEV/MODELS", isDirectory: true)
}
