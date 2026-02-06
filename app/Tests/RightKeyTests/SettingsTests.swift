import XCTest
@testable import RightKey

final class SettingsTests: XCTestCase {
    private let suiteName = "RightKeyTests.Settings"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: suiteName)!
    }

    func testDefaultSettings() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.streamingEnabled, true)
        XCTAssertEqual(settings.idleTimeoutSeconds, 90)
        XCTAssertEqual(settings.defaultModelID, ModelInfo.phi15.id)
        XCTAssertEqual(settings.llamaBinaryPath, "")
        XCTAssertEqual(settings.maxTokens, 256)
        XCTAssertEqual(settings.temperature, 0.7)
        XCTAssertEqual(settings.topP, 0.9)
        XCTAssertEqual(settings.useLlamaServer, true)
        XCTAssertEqual(settings.gpuLayers, 24)
    }

    func testInvalidDefaultModelFallsBack() {
        let defaults = makeDefaults()
        defaults.set("missing-model", forKey: "settings.model.default")
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.defaultModelID, ModelInfo.phi15.id)
    }

    func testOutOfRangeValuesAreNormalizedOnInit() {
        let defaults = makeDefaults()
        defaults.set(5.0, forKey: "settings.idle.timeout")
        defaults.set(-10, forKey: "settings.generation.maxTokens")
        defaults.set(2.5, forKey: "settings.generation.temperature")
        defaults.set(-1.0, forKey: "settings.generation.topP")
        defaults.set(999, forKey: "settings.llama.gpuLayers")
        defaults.set("  ~/bin/llama-cli  ", forKey: "settings.llama.binary")

        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.idleTimeoutSeconds, 30)
        XCTAssertEqual(settings.maxTokens, 64)
        XCTAssertEqual(settings.temperature, 1.5)
        XCTAssertEqual(settings.topP, 0.1)
        XCTAssertEqual(settings.gpuLayers, 64)
        XCTAssertEqual(settings.llamaBinaryPath, ("~/bin/llama-cli" as NSString).expandingTildeInPath)
    }

    func testOutOfRangeValuesAreNormalizedWhenUpdated() {
        let settings = AppSettings(defaults: makeDefaults())
        settings.idleTimeoutSeconds = 500
        settings.maxTokens = 9_999
        settings.temperature = -5
        settings.topP = 9
        settings.gpuLayers = -2
        settings.llamaBinaryPath = "  ~/custom/llama-cli  "

        XCTAssertEqual(settings.idleTimeoutSeconds, 300)
        XCTAssertEqual(settings.maxTokens, 1024)
        XCTAssertEqual(settings.temperature, 0.0)
        XCTAssertEqual(settings.topP, 1.0)
        XCTAssertEqual(settings.gpuLayers, 0)
        XCTAssertEqual(settings.llamaBinaryPath, ("~/custom/llama-cli" as NSString).expandingTildeInPath)
    }
}
