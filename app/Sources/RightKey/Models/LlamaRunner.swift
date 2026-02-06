import Foundation

enum LlamaRuntime {
    static func resolveBinaryURL(settings: AppSettings) -> URL? {
        if settings.llamaBinaryPath.isEmpty == false {
            let url = URL(fileURLWithPath: settings.llamaBinaryPath)
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return url
            }
        }
        return locateBinaryURL()
    }

    static func resolveServerURL(settings: AppSettings) -> URL? {
        if settings.llamaBinaryPath.isEmpty == false {
            let pathURL = URL(fileURLWithPath: settings.llamaBinaryPath)
            if pathURL.lastPathComponent == "llama-server" {
                return FileManager.default.isExecutableFile(atPath: pathURL.path) ? pathURL : nil
            }
            let candidate = pathURL.deletingLastPathComponent().appendingPathComponent("llama-server")
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return locateServerURL()
    }

    static func locateBinaryURL() -> URL? {
        let environment = ProcessInfo.processInfo.environment
        let envKeys = ["LLAMA_BIN", "LLAMA_CPP_BIN"]
        for key in envKeys {
            if let path = environment[key], FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        let candidates = [
            "/opt/homebrew/bin/llama-cli",
            "/usr/local/bin/llama-cli",
            "/opt/homebrew/bin/llama",
            "/usr/local/bin/llama",
            "/opt/homebrew/bin/main",
            "/usr/local/bin/main"
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    static func locateServerURL() -> URL? {
        let environment = ProcessInfo.processInfo.environment
        let envKeys = ["LLAMA_SERVER_BIN", "LLAMA_CPP_SERVER_BIN"]
        for key in envKeys {
            if let path = environment[key], FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        let candidates = [
            "/opt/homebrew/bin/llama-server",
            "/usr/local/bin/llama-server"
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    static func resolveQuantizeURL(settings: AppSettings) -> URL? {
        if settings.llamaBinaryPath.isEmpty == false {
            let baseURL = URL(fileURLWithPath: settings.llamaBinaryPath).deletingLastPathComponent()
            let candidate = baseURL.appendingPathComponent("llama-quantize")
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return locateQuantizeURL()
    }

    static func locateQuantizeURL() -> URL? {
        let environment = ProcessInfo.processInfo.environment
        let envKeys = ["LLAMA_QUANTIZE_BIN", "LLAMA_CPP_QUANTIZE_BIN"]
        for key in envKeys {
            if let path = environment[key], FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        let candidates = [
            "/opt/homebrew/bin/llama-quantize",
            "/usr/local/bin/llama-quantize"
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    static func resolveConverterURL(settings: AppSettings) -> URL? {
        let environment = ProcessInfo.processInfo.environment
        let envKeys = ["LLAMA_CONVERT_PATH", "LLAMA_CPP_CONVERT_PATH"]
        for key in envKeys {
            if let path = environment[key], FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        if settings.llamaBinaryPath.isEmpty == false {
            let baseURL = URL(fileURLWithPath: settings.llamaBinaryPath).deletingLastPathComponent()
            let candidate = baseURL.appendingPathComponent("convert_hf_to_gguf.py")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        let brewCandidates = [
            URL(fileURLWithPath: "/opt/homebrew/Cellar/llama.cpp"),
            URL(fileURLWithPath: "/usr/local/Cellar/llama.cpp")
        ]
        for root in brewCandidates {
            if let converter = locateConverterInCellar(root: root) {
                return converter
            }
        }
        return nil
    }

    private static func locateConverterInCellar(root: URL) -> URL? {
        guard let versions = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
            return nil
        }
        for versionURL in versions {
            let binCandidate = versionURL.appendingPathComponent("bin/convert_hf_to_gguf.py")
            if FileManager.default.fileExists(atPath: binCandidate.path) {
                return binCandidate
            }
            let libexecCandidate = versionURL.appendingPathComponent("libexec/convert_hf_to_gguf.py")
            if FileManager.default.fileExists(atPath: libexecCandidate.path) {
                return libexecCandidate
            }
        }
        return nil
    }

    static var installHint: String {
        "Install llama.cpp with `brew install llama.cpp`, set LLAMA_BIN, or pick the binary in Preferences."
    }
}

final class LlamaRunner {
    struct Config {
        let cliURL: URL
        let serverURL: URL?
        let modelURL: URL
        let maxTokens: Int
        let temperature: Double
        let topP: Double
        let contextSize: Int
        let useServer: Bool
        let gpuLayers: Int
    }

    private struct ServerConfig: Equatable {
        let modelPath: String
        let contextSize: Int
        let gpuLayers: Int
    }

    private let serverHost = "127.0.0.1"
    private let serverPort = 50951
    private var serverProcess: Process?
    private var serverConfig: ServerConfig?

    func streamResponse(prompt: String, config: Config) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                if config.useServer, let serverURL = config.serverURL {
                    await streamViaServer(prompt: prompt, config: config, serverURL: serverURL, continuation: continuation)
                } else {
                    streamViaCli(prompt: prompt, config: config, continuation: continuation)
                }
            }
        }
    }

    func stopServer() {
        if let serverProcess, serverProcess.isRunning {
            serverProcess.terminate()
        }
        serverProcess = nil
        serverConfig = nil
    }

    private func streamViaCli(prompt: String, config: Config, continuation: AsyncStream<String>.Continuation) {
        let process = Process()
        process.executableURL = config.cliURL
        var arguments = [
            "--model", config.modelURL.path,
            "--prompt", prompt,
            "--n-predict", String(config.maxTokens),
            "--temp", String(config.temperature),
            "--top-p", String(config.topP),
            "--ctx-size", String(config.contextSize),
            "--no-display-prompt"
        ]
        if config.gpuLayers > 0 {
            arguments.append(contentsOf: ["--n-gpu-layers", String(config.gpuLayers)])
        }
        process.arguments = arguments
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = FileHandle.nullDevice
        let outputHandle = outputPipe.fileHandleForReading

        outputHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard data.isEmpty == false else { return }
            if let chunk = String(data: data, encoding: .utf8), chunk.isEmpty == false {
                continuation.yield(chunk)
            }
        }

        process.terminationHandler = { _ in
            outputHandle.readabilityHandler = nil
            let remaining = outputHandle.readDataToEndOfFile()
            if let chunk = String(data: remaining, encoding: .utf8), chunk.isEmpty == false {
                continuation.yield(chunk)
            }
            continuation.finish()
        }

        do {
            try process.run()
        } catch {
            outputHandle.readabilityHandler = nil
            continuation.yield("Failed to run llama.cpp: \(error.localizedDescription)")
            continuation.finish()
        }

        continuation.onTermination = { _ in
            outputHandle.readabilityHandler = nil
            if process.isRunning {
                process.terminate()
            }
        }
    }

    private func streamViaServer(
        prompt: String,
        config: Config,
        serverURL: URL,
        continuation: AsyncStream<String>.Continuation
    ) async {
        do {
            try await ensureServerRunning(config: config, serverURL: serverURL)
            let endpoint = URL(string: "http://\(serverHost):\(serverPort)/completion")!
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = [
                "prompt": prompt,
                "n_predict": config.maxTokens,
                "temperature": config.temperature,
                "top_p": config.topP,
                "stream": true
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            try validateServerResponse(response)
            for try await line in bytes.lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.hasPrefix("data:") else { continue }
                let payload = trimmed.replacingOccurrences(of: "data:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if payload == "[DONE]" {
                    break
                }
                if let chunk = decodeServerChunk(payload) {
                    continuation.yield(chunk)
                }
            }
            continuation.finish()
        } catch {
            continuation.yield("Llama server error: \(error.localizedDescription)")
            continuation.finish()
        }
    }

    private func ensureServerRunning(config: Config, serverURL: URL) async throws {
        let nextConfig = ServerConfig(
            modelPath: config.modelURL.path,
            contextSize: config.contextSize,
            gpuLayers: config.gpuLayers
        )
        if serverConfig != nextConfig || serverProcess?.isRunning != true {
            stopServer()
            try startServer(config: nextConfig, serverURL: serverURL)
            try await waitForServerReady()
        }
    }

    private func startServer(config: ServerConfig, serverURL: URL) throws {
        let process = Process()
        process.executableURL = serverURL
        var arguments = [
            "--model", config.modelPath,
            "--host", serverHost,
            "--port", String(serverPort),
            "--ctx-size", String(config.contextSize)
        ]
        if config.gpuLayers > 0 {
            arguments.append(contentsOf: ["--n-gpu-layers", String(config.gpuLayers)])
        }
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        serverProcess = process
        serverConfig = config
    }

    private func waitForServerReady() async throws {
        let url = URL(string: "http://\(serverHost):\(serverPort)/health")!
        for _ in 0..<50 {
            do {
                let (_, response) = try await URLSession.shared.data(from: url)
                if response is HTTPURLResponse {
                    return
                }
            } catch {
                try await Task.sleep(nanoseconds: 200_000_000)
            }
        }
        throw LlamaRunnerError.serverNotReady
    }

    private func decodeServerChunk(_ payload: String) -> String? {
        guard let data = payload.data(using: .utf8) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let content = json["content"] as? String {
            return content
        }
        if let choices = json["choices"] as? [[String: Any]],
           let text = choices.first?["text"] as? String {
            return text
        }
        return nil
    }

    private func validateServerResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw LlamaRunnerError.serverHttp(code: http.statusCode)
        }
    }
}

enum LlamaRunnerError: LocalizedError {
    case serverNotReady
    case serverHttp(code: Int)

    var errorDescription: String? {
        switch self {
        case .serverNotReady:
            return "Server did not start in time."
        case .serverHttp(let code):
            return "Server returned HTTP \(code)."
        }
    }
}
