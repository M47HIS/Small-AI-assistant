import XCTest
@testable import RightKey

final class PromptBuilderTests: XCTestCase {
    func testPromptIncludesContext() {
        let context = ContextSnapshot(clipboardText: "hello", frontmostAppName: "Notes")
        let prompt = PromptBuilder.buildPrompt(input: "Summarize", context: context)
        XCTAssertTrue(prompt.contains("Frontmost app: Notes"))
        XCTAssertTrue(prompt.contains("Clipboard: hello"))
        XCTAssertTrue(prompt.contains("User: Summarize"))
    }
}
