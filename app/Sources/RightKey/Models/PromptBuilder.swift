import Foundation

struct PromptBuilder {
    static func buildPrompt(input: String, context: ContextSnapshot) -> String {
        var lines: [String] = [
            "You are RightKey, a compact local assistant.",
            "Frontmost app: \(context.frontmostAppName)."
        ]

        if context.clipboardText.isEmpty == false {
            let clipped = String(context.clipboardText.prefix(200))
            lines.append("Clipboard: \(clipped)")
        }

        lines.append("")
        lines.append("User: \(input)")
        return lines.joined(separator: "\n")
    }
}
