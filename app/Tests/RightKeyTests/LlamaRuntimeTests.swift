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

    func testLocateBinaryFromEnvExpandsTildePath() throws {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let tempDir = homeDirectory.appendingPathComponent("tmp")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let tempURL = tempDir.appendingPathComponent("rightkey-llama-env-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: tempURL.path, contents: Data())
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempURL.path)
        let tildePath = "~/" + tempURL.path.dropFirst(homeDirectory.path.count + 1)
        setenv("LLAMA_BIN", String(tildePath), 1)
        defer {
            unsetenv("LLAMA_BIN")
            try? FileManager.default.removeItem(at: tempURL)
        }

        let located = LlamaRuntime.locateBinaryURL()
        XCTAssertEqual(located?.path, tempURL.path)
    }

    func testResolveBinaryFromSettingsExpandsTildePath() throws {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let tempDir = homeDirectory.appendingPathComponent("tmp")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let tempURL = tempDir.appendingPathComponent("rightkey-llama-settings-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: tempURL.path, contents: Data())
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempURL.path)
        let defaults = UserDefaults(suiteName: "RightKeyRuntimeTestsTilde")!
        defaults.removePersistentDomain(forName: "RightKeyRuntimeTestsTilde")
        let settings = AppSettings(defaults: defaults)
        settings.llamaBinaryPath = "~/" + tempURL.path.dropFirst(homeDirectory.path.count + 1)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let located = LlamaRuntime.resolveBinaryURL(settings: settings)
        XCTAssertEqual(located?.path, tempURL.path)
    }
}
