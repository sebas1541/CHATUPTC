import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: ChatViewModel
    @State private var search = ""

    private var filtered: [Conversation] {
        let all = viewModel.store.conversations
        guard !search.isEmpty else { return all }
        return all.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 14)

            sectionHeader
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 2) {
                    ForEach(filtered) { conv in
                        ConversationRow(
                            conversation: conv,
                            isSelected: viewModel.store.selectedID == conv.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectConversation(conv.id)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.store.deleteConversation(conv.id)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .scrollContentBackground(.hidden)

            Spacer(minLength: 0)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // settings (no-op por ahora)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.primary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help("Configuración")
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField("Search", text: $search)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.06), in: Capsule())
    }

    private var sectionHeader: some View {
        HStack {
            Text("All conversations")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

private struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(conversation.title)
                .font(.system(size: 13, weight: .regular))
                .lineLimit(1)
                .foregroundStyle(.primary)
            Text(conversation.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
        )
    }
}
