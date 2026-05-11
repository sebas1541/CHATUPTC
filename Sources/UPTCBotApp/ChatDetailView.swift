import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ChatDetailView: View {
    @Bindable var viewModel: ChatViewModel

    @State private var input = ""
    @State private var isDropTargeted = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        rootStack
            .onDrop(
                of: [.fileURL, .image],
                isTargeted: $isDropTargeted
            ) { providers in
                handleDrop(providers: providers)
            }
            .overlay {
                if isDropTargeted {
                    dropHintOverlay
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
    }

    private var rootStack: some View {
        VStack(spacing: 0) {
            Group {
                switch viewModel.modelState {
                case .idle, .loading:
                    loadingView
                case .failed(let msg):
                    errorView(msg)
                case .ready:
                    messagesScroll
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ComposerView(
                text: $input,
                isFocused: $inputFocused,
                canSend: canSend,
                isGenerating: viewModel.isGenerating,
                attachment: viewModel.pendingAttachment,
                onSend: send,
                onStop: viewModel.stopGeneration,
                onAttachImage: presentImagePicker,
                onRemoveAttachment: viewModel.clearAttachment
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .padding(.top, 4)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    // MARK: Messages

    private var messagesScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if viewModel.messages.isEmpty {
                        emptyState
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else {
                        LazyVStack(spacing: 18) {
                            ForEach(viewModel.messages) { msg in
                                MessageView(
                                    message: msg,
                                    isLast: viewModel.messages.last?.id == msg.id,
                                    isGenerating: viewModel.isGenerating
                                )
                                .id(msg.id)
                            }
                            Color.clear.frame(height: 8).id("bottom")
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.messages.last?.text) { _, _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: States

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.tint)
            }

            VStack(spacing: 6) {
                Text("UPTCBot")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.primary, Color.primary.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("Tu asistente local sobre los programas\nde pregrado de la UPTC en Tunja")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            VStack(spacing: 8) {
                Text("Prueba con")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .padding(.top, 8)

                HStack(spacing: 8) {
                    promptChip("¿Qué facultades hay en Tunja?")
                    promptChip("Recomiéndame uno con IA")
                }
                HStack(spacing: 8) {
                    promptChip("¿Cuántos créditos tiene Sistemas?")
                    promptChip("Programas con más matemáticas")
                }
            }
        }
        .padding(.vertical, 24)
    }

    private func promptChip(_ text: String) -> some View {
        Button {
            input = text
            inputFocused = true
        } label: {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.05))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.regular)
            Text("Cargando Fine-tuned Gemma UPTC…")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Text("Mapeando 3.3 GB a memoria, ~10–30s la primera vez")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(.orange)
            Text("No pude cargar el modelo")
                .font(.system(size: 15, weight: .semibold))
            Text(msg)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: Send / Attach

    private var canSend: Bool {
        let hasText = !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = viewModel.pendingAttachment != nil
        return (hasText || hasImage)
            && !viewModel.isGenerating
            && viewModel.modelState == .ready
    }

    private func send() {
        let text = input
        input = ""
        viewModel.send(text)
    }

    private func presentImagePicker() {
        let panel = NSOpenPanel()
        panel.title = "Adjuntar imagen"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .png, .jpeg, .heic, .tiff, .gif]
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.attachImage(url)
        }
    }

    // MARK: Drag & drop

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // Prefer file URL (Finder, Pictures, etc.)
        if provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url, isAcceptableImage(url) else { return }
                Task { @MainActor in
                    viewModel.attachImage(url)
                }
            }
            return true
        }

        // Fallback: image data (browser drag)
        if provider.canLoadObject(ofClass: NSImage.self) {
            _ = provider.loadObject(ofClass: NSImage.self) { image, _ in
                guard let image = image as? NSImage else { return }
                if let url = saveTempImage(image) {
                    Task { @MainActor in
                        viewModel.attachImage(url)
                    }
                }
            }
            return true
        }

        return false
    }

    private func isAcceptableImage(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return false
        }
        return type.conforms(to: .image)
    }

    /// Guarda una imagen arrastrada desde browser/Photos a un archivo temporal
    /// para poder pasársela al modelo como URL.
    private func saveTempImage(_ image: NSImage) -> URL? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("UPTCBot", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let url = tempDir.appendingPathComponent("dropped-\(UUID().uuidString).png")
        do {
            try pngData.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    private var dropHintOverlay: some View {
        ZStack {
            Color.accentColor.opacity(0.08)
            VStack(spacing: 14) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.tint)
                Text("Suelta la imagen para adjuntarla")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.tint)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [10, 6]))
                .foregroundStyle(.tint)
                .padding(16)
        )
        .allowsHitTesting(false)
    }
}
