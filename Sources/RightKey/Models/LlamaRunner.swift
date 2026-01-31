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

    static var installHint: String {
        "Install llama.cpp with `brew install llama.cpp`, set LLAMA_BIN, or pick the binary in Preferences."
    }
}

final class LlamaRunner {
    struct Config {
        let binaryURL: URL
        let modelURL: URL
        let maxTokens: Int
        let temperature: Double
        let topP: Double
        let contextSize: Int
    }

    func streamResponse(prompt: String, config: Config) -> AsyncStream<String> {
        AsyncStream { continuation in
            let process = Process()
            process.executableURL = config.binaryURL
            process.arguments = [
                "--model", config.modelURL.path,
                "--prompt", prompt,
                "--n-predict", String(config.maxTokens),
                "--temp", String(config.temperature),
                "--top-p", String(config.topP),
                "--ctx-size", String(config.contextSize),
                "--no-display-prompt"
            ]
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
    }
}
