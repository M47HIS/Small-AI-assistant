import Foundation
import XCTest
@testable import RightKey

final class LlamaRuntimeTests: XCTestCase {
    func testLocateBinaryFromEnv() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("llama-test-bin")
        FileManager.default.createFile(atPath: tempURL.path, contents: Data())
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempURL.path)
        setenv("LLAMA_BIN", tempURL.path, 1)
        defer {
            unsetenv("LLAMA_BIN")
            try? FileManager.default.removeItem(at: tempURL)
        }

        let located = LlamaRuntime.locateBinaryURL()
        XCTAssertEqual(located?.path, tempURL.path)
    }

    func testResolveBinaryFromSettings() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("llama-test-bin-settings")
        FileManager.default.createFile(atPath: tempURL.path, contents: Data())
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempURL.path)
        let defaults = UserDefaults(suiteName: "RightKeyRuntimeTests")!
        defaults.removePersistentDomain(forName: "RightKeyRuntimeTests")
        let settings = AppSettings(defaults: defaults)
        settings.llamaBinaryPath = tempURL.path
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let located = LlamaRuntime.resolveBinaryURL(settings: settings)
        XCTAssertEqual(located?.path, tempURL.path)
    }
}
