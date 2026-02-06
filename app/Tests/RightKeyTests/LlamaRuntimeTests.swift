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

    func testResolveServerFromSiblingPath() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let cliURL = tempDir.appendingPathComponent("llama-cli")
        let serverURL = tempDir.appendingPathComponent("llama-server")
        FileManager.default.createFile(atPath: cliURL.path, contents: Data())
        FileManager.default.createFile(atPath: serverURL.path, contents: Data())
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: cliURL.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: serverURL.path)
        let defaults = UserDefaults(suiteName: "RightKeyRuntimeTests")!
        defaults.removePersistentDomain(forName: "RightKeyRuntimeTests")
        let settings = AppSettings(defaults: defaults)
        settings.llamaBinaryPath = cliURL.path
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let located = LlamaRuntime.resolveServerURL(settings: settings)
        XCTAssertEqual(located?.path, serverURL.path)
    }
}
