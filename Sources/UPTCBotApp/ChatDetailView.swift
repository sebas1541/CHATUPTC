import SwiftUI

struct ChatDetailView: View {
    @Bindable var viewModel: ChatViewModel
    let sidebarHidden: Bool
    let onShowSidebar: () -> Void
    let onNewChat: () -> Void

    @State private var input = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
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
                canSend: !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && !viewModel.isGenerating
                    && viewModel.modelState == .ready,
                isGenerating: viewModel.isGenerating,
                onSend: send,
                onStop: viewModel.stopGeneration
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .padding(.top, 4)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .toolbar {
            // Cuando el sidebar está oculto, mostramos gear + sidebar.left aquí
            // para poder reabrir + acceder a settings.
            if sidebarHidden {
                ToolbarItem(placement: .navigation) {
                    Button { /* settings (no-op) */ } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                    }
                    .help("Configuración")
                }
                ToolbarItem(placement: .navigation) {
                    Button(action: onShowSidebar) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 14))
                    }
                    .help("Mostrar sidebar")
                }
            }
            ToolbarItem(placement: .principal) {
                ModelPill()
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: onNewChat) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14))
                }
                .help("Nuevo chat")
            }
        }
    }

    // MARK: Messages

    private var messagesScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 18) {
                    if viewModel.messages.isEmpty {
                        emptyState
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else {
                        ForEach(viewModel.messages) { msg in
                            MessageView(
                                message: msg,
                                isLast: viewModel.messages.last?.id == msg.id,
                                isGenerating: viewModel.isGenerating
                            )
                            .id(msg.id)
                        }
                    }
                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 16)
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
        VStack(spacing: 8) {
            Text("UPTCBot")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.primary)
            Text("Pregúntame sobre los programas de pregrado de la UPTC en Tunja")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
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

    // MARK: Send

    private func send() {
        let text = input
        input = ""
        viewModel.send(text)
    }
}

private struct ModelPill: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Fine-tuned Gemma UPTC")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: .capsule)
        .overlay(
            Capsule().stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }
}
