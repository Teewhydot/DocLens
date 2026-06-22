import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel = HomeViewModel(documents: SampleData.documents)) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmpty {
                    emptyState
                } else {
                    documentList
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("DocLens")
            .toolbar { toolbarContent }
            .confirmationDialog("Import Document", isPresented: $viewModel.showImportOptions, titleVisibility: .visible) {
                Button("Import PDF") {}
                Button("Import Image") {}
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete Document?", isPresented: deletionBinding) {
                Button("Delete", role: .destructive) { viewModel.confirmDelete() }
                Button("Cancel", role: .cancel) { viewModel.pendingDeletion = nil }
            } message: {
                Text("This will permanently remove “\(viewModel.pendingDeletion?.title ?? "")” and its analysis.")
            }
        }
    }

    // MARK: Subviews

    private var documentList: some View {
        List {
            Section {
                ForEach(viewModel.documents) { doc in
                    DocumentCell(document: doc)
                        .listRowInsets(EdgeInsets(top: 4, leading: Theme.rowHPadding, bottom: 4, trailing: Theme.rowHPadding))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.requestDelete(doc)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            } header: {
                Text("\(viewModel.documents.count) document\(viewModel.documents.count == 1 ? "" : "s")")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        EmptyStateView(
            symbol: "doc.text.magnifyingglass",
            title: "No documents yet",
            message: "Import your first contract to get started. Everything is analyzed privately, right on your device.",
            ctaTitle: "Import Document",
            action: { viewModel.showImportOptions = true }
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.showImportOptions = true
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
            }
            .accessibilityLabel("Import document")
        }
    }

    private var deletionBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingDeletion != nil },
            set: { if !$0 { viewModel.pendingDeletion = nil } }
        )
    }
}

#Preview("Populated") {
    HomeView(viewModel: .mock)
}

#Preview("Empty") {
    HomeView(viewModel: .mockEmpty)
}
