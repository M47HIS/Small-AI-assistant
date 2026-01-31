import Cocoa
import SwiftUI

final class OverlayWindowController {
    private let window: NSPanel
    private let modelManager: ModelManager
    private let settings: AppSettings
    private let onOpenPreferences: () -> Void
    private let panelWidth: CGFloat = 600
    private let minPanelHeight: CGFloat = 76
    private let maxPanelHeight: CGFloat = 260
    private var currentHeight: CGFloat

    init(modelManager: ModelManager, settings: AppSettings, onOpenPreferences: @escaping () -> Void) {
        self.modelManager = modelManager
        self.settings = settings
        self.onOpenPreferences = onOpenPreferences
        self.currentHeight = minPanelHeight

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: minPanelHeight),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.window = panel
        let contentView = ChatBarView(
            modelManager: modelManager,
            settings: settings,
            panelWidth: panelWidth,
            onHeightChange: { [weak panel, weak self] height in
                guard let self, panel != nil else { return }
                self.updateWindowHeight(height)
            },
            onOpenPreferences: onOpenPreferences,
            onClose: { [weak panel] in
                panel?.orderOut(nil)
            }
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.tabbingMode = .disallowed
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.contentView = NSHostingView(rootView: contentView)
    }

    func toggle() {
        if window.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        positionTopRight(height: currentHeight, animate: false)
        window.orderFrontRegardless()
        window.makeKey()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        window.orderOut(nil)
    }

    private func updateWindowHeight(_ height: CGFloat) {
        let clamped = max(minPanelHeight, min(height, maxPanelHeight))
        guard abs(clamped - currentHeight) > 1 else { return }
        currentHeight = clamped
        positionTopRight(height: clamped, animate: true)
    }

    private func positionTopRight(height: CGFloat, animate: Bool) {
        guard let screen = targetScreen() else { return }
        let frame = screen.visibleFrame
        let width: CGFloat = panelWidth
        let margin: CGFloat = 24
        let origin = CGPoint(
            x: frame.maxX - width - margin,
            y: frame.maxY - height - margin
        )
        window.setFrame(NSRect(origin: origin, size: CGSize(width: width, height: height)), display: true, animate: animate)
    }

    private func targetScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main ?? NSScreen.screens.first
    }
}
