import SwiftUI

struct ContentView: View {
    @State private var store = ConversationStore()
    @State private var viewModel: ChatViewModel?
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        Group {
            if let viewModel {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    SidebarView(viewModel: viewModel)
                        .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
                } detail: {
                    ChatDetailView(viewModel: viewModel)
                }
                .navigationSplitViewStyle(.balanced)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        ModelPill()
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: viewModel.newChat) {
                            iconLabel("square.and.pencil")
                        }
                        .buttonStyle(.plain)
                        .help("Nuevo chat")
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            if viewModel == nil {
                let vm = ChatViewModel(store: store)
                self.viewModel = vm
                vm.loadModelIfNeeded()
            }
        }
    }

    @ViewBuilder
    private func iconLabel(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(.primary)
            .frame(width: 28, height: 28)
    }
}

struct ModelPill: View {
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
