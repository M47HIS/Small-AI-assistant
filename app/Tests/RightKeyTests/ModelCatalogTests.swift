import XCTest
@testable import RightKey

final class ModelCatalogTests: XCTestCase {
    func testCatalogHasDefaults() {
        let ids = Set(ModelInfo.available.map { $0.id })
        XCTAssertTrue(ids.contains("phi-1.5-q4"))
        XCTAssertTrue(ids.contains("tinyllama-1.1b-q4"))
        XCTAssertTrue(ids.contains("phi-1.5-hf"))
    }
}
