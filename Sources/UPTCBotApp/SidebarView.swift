import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: ChatViewModel
    let onHideSidebar: () -> Void

    @State private var search = ""

    private var filtered: [Conversation] {
        let all = viewModel.store.conversations
        guard !search.isEmpty else { return all }
        return all.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(spacing: 0) {
            inlineHeader
                .padding(.top, 14)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)

            searchField
                .padding(.horizontal, 12)
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
        // Removemos el sidebar toggle del sistema porque tenemos uno propio inline
        .toolbar(removing: .sidebarToggle)
    }

    // MARK: Inline gear + sidebar.left dentro del body

    private var inlineHeader: some View {
        HStack(spacing: 4) {
            Spacer().frame(width: 56) // espacio para los traffic lights
            Spacer()
            inlineIcon("gearshape") { /* settings (no-op) */ }
            inlineIcon("sidebar.left", action: onHideSidebar)
        }
        .frame(height: 28)
    }

    private func inlineIcon(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: Search

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
