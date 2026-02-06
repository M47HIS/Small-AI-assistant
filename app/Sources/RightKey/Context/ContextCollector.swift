import AppKit

struct ContextSnapshot {
    let clipboardText: String
    let frontmostAppName: String
}

enum ContextCollector {
    static func capture() -> ContextSnapshot {
        let clipboard: String
        if NSRunningApplication.current.isActive {
            clipboard = NSPasteboard.general.string(forType: .string) ?? ""
        } else {
            clipboard = ""
        }
        let appName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown App"
        return ContextSnapshot(clipboardText: clipboard, frontmostAppName: appName)
    }
}
