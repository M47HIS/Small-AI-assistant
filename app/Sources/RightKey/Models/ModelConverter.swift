import Foundation

final class ModelConverter {
    func convert(model: ModelInfo, settings: AppSettings) async throws {
        guard model.requiresConversion else { return }
        guard let converterURL = LlamaRuntime.resolveConverterURL(settings: settings) else {
            throw ModelConversionError.converterMissing
        }
        guard let quantizeURL = LlamaRuntime.resolveQuantizeURL(settings: settings) else {
            throw ModelConversionError.quantizeMissing
        }
        let python = PythonRuntime.resolve()
        try validateWorkingDirectory(model: model)
        try removeExistingOutput(model: model)

        let conversionArguments = python.argumentsPrefix + [
            converterURL.path,
            model.workingDirectory.path,
            "--outtype", "f16",
            "--outfile", model.intermediateURL.path
        ]
        try await runProcess(
            executableURL: python.executableURL,
            arguments: conversionArguments,
            environment: ["TRANSFORMERS_OFFLINE": "1"]
        )

        let quantizeArguments = [
            model.intermediateURL.path,
            model.outputURL.path,
            model.quantization
        ]
        try await runProcess(
            executableURL: quantizeURL,
            arguments: quantizeArguments,
            environment: nil
        )

        try? FileManager.default.removeItem(at: model.intermediateURL)
    }

    private func validateWorkingDirectory(model: ModelInfo) throws {
        for file in model.filesToDownload {
            let url = model.workingDirectory.appendingPathComponent(file)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ModelConversionError.missingFile(file)
            }
        }
    }

    private func removeExistingOutput(model: ModelInfo) throws {
        if FileManager.default.fileExists(atPath: model.outputURL.path) {
            try FileManager.default.removeItem(at: model.outputURL)
        }
        if FileManager.default.fileExists(atPath: model.intermediateURL.path) {
            try FileManager.default.removeItem(at: model.intermediateURL)
        }
    }

    private func runProcess(
        executableURL: URL,
        arguments: [String],
        environment: [String: String]?
    ) async throws {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        var environmentValues = ProcessInfo.processInfo.environment
        if let environment {
            environmentValues.merge(environment) { _, new in new }
        }
        process.environment = environmentValues

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = FileHandle.nullDevice

        try process.run()
        try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                let status = process.terminationStatus
                if status == 0 {
                    continuation.resume()
                    return
                }
                let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let message = String(data: data, encoding: .utf8) ?? "Process failed"
                continuation.resume(throwing: ModelConversionError.processFailed(message.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
    }
}

enum ModelConversionError: LocalizedError {
    case converterMissing
    case quantizeMissing
    case missingFile(String)
    case processFailed(String)

    var errorDescription: String? {
        switch self {
        case .converterMissing:
            return "convert_hf_to_gguf.py not found. Install llama.cpp or set LLAMA_CONVERT_PATH."
        case .quantizeMissing:
            return "llama-quantize not found. Install llama.cpp or set LLAMA_QUANTIZE_BIN."
        case .missingFile(let file):
            return "Missing required file \(file). Re-download the model files."
        case .processFailed(let message):
            return "Conversion failed: \(message)"
        }
    }
}

private struct PythonRuntime {
    let executableURL: URL
    let argumentsPrefix: [String]

    static func resolve() -> PythonRuntime {
        let environment = ProcessInfo.processInfo.environment
        if let path = environment["PYTHON_BIN"], FileManager.default.isExecutableFile(atPath: path) {
            return PythonRuntime(executableURL: URL(fileURLWithPath: path), argumentsPrefix: [])
        }
        return PythonRuntime(executableURL: URL(fileURLWithPath: "/usr/bin/env"), argumentsPrefix: ["python3"])
    }
}
