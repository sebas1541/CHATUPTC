import SwiftUI

struct ContentView: View {
    @State private var store = ConversationStore()
    @State private var viewModel: ChatViewModel?
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        Group {
            if let viewModel {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    SidebarView(
                        viewModel: viewModel,
                        onHideSidebar: { columnVisibility = .detailOnly }
                    )
                    .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
                } detail: {
                    ChatDetailView(
                        viewModel: viewModel,
                        sidebarHidden: columnVisibility == .detailOnly,
                        onShowSidebar: { columnVisibility = .all },
                        onNewChat: viewModel.newChat
                    )
                }
                .navigationSplitViewStyle(.balanced)
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
}
