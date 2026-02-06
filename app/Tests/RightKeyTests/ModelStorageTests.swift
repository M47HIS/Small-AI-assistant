import XCTest
@testable import RightKey

final class ModelStorageTests: XCTestCase {
    func testModelsDirectoryUsesApplicationSupport() {
        unsetenv("RIGHTKEY_MODELS_DIR")
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            XCTFail("Missing Application Support directory")
            return
        }

        let expected = appSupport
            .appendingPathComponent("RightKey", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
        XCTAssertEqual(ModelStorage.modelsDirectory, expected)
    }

    func testModelsDirectoryUsesOverrideWhenSet() {
        let override = "/tmp/rightkey-models-test"
        setenv("RIGHTKEY_MODELS_DIR", override, 1)
        defer { unsetenv("RIGHTKEY_MODELS_DIR") }

        XCTAssertEqual(ModelStorage.modelsDirectory, URL(fileURLWithPath: override, isDirectory: true))
    }

    func testModelsDirectoryExpandsTildeInOverride() {
        let override = "~/rightkey-models-test"
        setenv("RIGHTKEY_MODELS_DIR", override, 1)
        defer { unsetenv("RIGHTKEY_MODELS_DIR") }

        let expectedPath = (override as NSString).expandingTildeInPath
        XCTAssertEqual(ModelStorage.modelsDirectory, URL(fileURLWithPath: expectedPath, isDirectory: true))
    }
}
