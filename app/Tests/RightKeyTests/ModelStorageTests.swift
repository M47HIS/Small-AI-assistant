import XCTest
@testable import RightKey

final class ModelStorageTests: XCTestCase {
    func testModelsDirectoryUsesApplicationSupport() {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            XCTFail("Missing Application Support directory")
            return
        }

        let expected = appSupport
            .appendingPathComponent("RightKey", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
        XCTAssertEqual(ModelStorage.modelsDirectory, expected)
    }
}
