import AppKit
import SwiftUI

struct ChatBarView: View {
    @StateObject private var viewModel: ChatBarViewModel
    @State private var didAppear = false
    @State private var orbPulse = false
    @State private var lastReportedHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    private let onOpenPreferences: () -> Void
    private let onClose: () -> Void
    private let onHeightChange: (CGFloat) -> Void
    private let panelWidth: CGFloat

    private let glowBlue = Color(red: 0.2, green: 0.67, blue: 0.9)
    private let glowTeal = Color(red: 0.25, green: 0.85, blue: 0.7)
    private let glowAmber = Color(red: 1.0, green: 0.62, blue: 0.2)

    init(
        modelManager: ModelManager,
        settings: AppSettings,
        panelWidth: CGFloat,
        onHeightChange: @escaping (CGFloat) -> Void,
        onOpenPreferences: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: ChatBarViewModel(modelManager: modelManager, settings: settings))
        self.onOpenPreferences = onOpenPreferences
        self.onClose = onClose
        self.onHeightChange = onHeightChange
        self.panelWidth = panelWidth
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                inputPill
                if shouldShowResponse {
                    responseArea
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(18)
        }
        .frame(width: panelWidth)
        .opacity(didAppear ? 1 : 0)
        .scaleEffect(didAppear ? 1 : 0.98)
        .animation(.easeOut(duration: 0.2), value: didAppear)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: shouldShowResponse)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        reportHeight(proxy.size.height)
                    }
                    .onChange(of: proxy.size.height) { newValue in
                        reportHeight(newValue)
                    }
            }
        )
        .onExitCommand {
            onClose()
        }
        .onAppear {
            didAppear = true
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                orbPulse = true
            }
            DispatchQueue.main.async {
                isInputFocused = true
            }
            if viewModel.showDownloader {
                viewModel.downloadModelsIfNeeded()
            }
        }
    }

    private var shouldShowResponse: Bool {
        viewModel.showDownloader || viewModel.isSending || viewModel.responseText.isEmpty == false
    }

    private var selectedModelName: String {
        viewModel.models.first(where: { $0.id == viewModel.selectedModelID })?.name ?? "Model"
    }

    private var inputPill: some View {
        HStack(spacing: 12) {
            orbView
            TextField("Ask RightKey...", text: $viewModel.inputText)
                .textFieldStyle(.plain)
                .font(.custom("Avenir Next", size: 16))
                .foregroundColor(.primary)
                .focused($isInputFocused)
                .onSubmit {
                    viewModel.submit()
                }
            actionButton
            settingsMenu
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [glowBlue.opacity(0.18), glowAmber.opacity(0.08)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .blur(radius: 8)
                    .opacity(0.4)
            }
        )
    }

    private var orbView: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [glowBlue, glowTeal, glowAmber, glowBlue],
                        center: .center
                    )
                )
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
        }
        .scaleEffect(orbPulse ? 1.04 : 0.96)
        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: orbPulse)
    }

    private var actionButton: some View {
        let trimmed = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let iconName: String
        if viewModel.isSending {
            iconName = "hourglass"
        } else if trimmed.isEmpty {
            iconName = "mic.fill"
        } else {
            iconName = "arrow.up"
        }

        return Button {
            viewModel.submit()
        } label: {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [glowBlue, glowTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.return, modifiers: [.command])
        .disabled(viewModel.isSending)
        .opacity(viewModel.isSending ? 0.7 : 1)
    }

    private var settingsMenu: some View {
        Menu {
            ForEach(viewModel.models) { model in
                Button {
                    viewModel.updateSelectedModel(model.id)
                } label: {
                    if model.id == viewModel.selectedModelID {
                        Label(model.name, systemImage: "checkmark")
                    } else {
                        Text(model.name)
                    }
                }
            }
            Divider()
            Button("Preferences") {
                onOpenPreferences()
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedModelName)
                    .font(.custom("Avenir Next", size: 13))
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }

    private var responseArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.showDownloader {
                downloadView
            } else {
                ScrollView {
                    Text(viewModel.responseText.isEmpty ? "Thinking..." : viewModel.responseText)
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, viewModel.isSending ? 8 : 0)
                }
                .frame(height: 170)

                if viewModel.isSending {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var downloadView: some View {
        let modelsPath = ModelStorage.modelsDirectory.path
        return VStack(alignment: .leading, spacing: 8) {
            Text("Model setup")
                .font(.custom("Avenir Next Demi Bold", size: 12))
            Text(viewModel.downloadStatus.isEmpty ? "Saving to \(modelsPath)" : viewModel.downloadStatus)
                .font(.custom("Avenir Next", size: 10))
                .foregroundColor(.secondary)
            if viewModel.isDownloading {
                ProgressView()
            }
            ForEach(viewModel.models) { model in
                Link("Open \(model.name) page", destination: model.repoURL)
                    .font(.custom("Avenir Next", size: 10))
            }
            Button("Reveal downloads folder") {
                NSWorkspace.shared.open(ModelStorage.modelsDirectory)
            }
            .font(.custom("Avenir Next", size: 10))
            if let error = viewModel.downloadError {
                Text(error)
                    .font(.custom("Avenir Next", size: 10))
                    .foregroundColor(.red)
                Button("Retry") {
                    viewModel.downloadModelsIfNeeded()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func reportHeight(_ height: CGFloat) {
        guard abs(height - lastReportedHeight) > 1 else { return }
        lastReportedHeight = height
        onHeightChange(height)
    }
}
