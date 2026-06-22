import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var store: DocumentStore
    @State private var showImportOptions = false
    @State private var showFilePicker = false
    @State private var showImagePicker = false
    @State private var pendingDeletion: DocumentEntity?
    @State private var selectedDoc: DocumentEntity?

    var body: some View {
        NavigationStack {
            Group {
                if store.documents.isEmpty {
                    emptyState
                } else {
                    documentList
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("DocLens")
            .toolbar { toolbarContent }
            .confirmationDialog("Import Document", isPresented: $showImportOptions, titleVisibility: .visible) {
                Button("Import PDF") { showFilePicker = true }
                Button("Import Image") { showImagePicker = true }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete Document?", isPresented: deletionActiveBinding) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: {
                Text("This will permanently remove \"\(pendingDeletion?.title ?? "")\" and its analysis.")
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf]) { result in
                handleImport(result: result, type: .pdf)
            }
            .sheet(item: $selectedDoc) { doc in
                DocumentViewerView(document: doc, fileURL: nil)
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Document List

    private var documentList: some View {
        List {
            Section {
                ForEach(store.documents) { doc in
                    Button {
                        selectedDoc = doc
                    } label: {
                        DocumentCell(document: doc)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 4, leading: Theme.rowHPadding, bottom: 4, trailing: Theme.rowHPadding))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            pendingDeletion = doc
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                let n = store.documents.count
                Text("\(n) document\(n == 1 ? "" : "s")")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            symbol: "doc.text.magnifyingglass",
            title: "No documents yet",
            message: "Import your first contract to get started. Everything is analyzed privately, right on your device.",
            ctaTitle: "Import Document",
            action: { showImportOptions = true }
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showImportOptions = true
            } label: {
                Image(systemName: "plus").font(.headline)
            }
            .accessibilityLabel("Import document")
        }
    }

    // MARK: - Helpers

    private var deletionActiveBinding: Binding<Bool> {
        Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })
    }

    private func confirmDelete() {
        if let doc = pendingDeletion { store.delete(doc) }
        pendingDeletion = nil
    }

    private func handleImport(result: Result<URL, Error>, type: FileType) {
        guard case .success(let url) = result else { return }
        let title = url.deletingPathExtension().lastPathComponent
        let doc = DocumentEntity(title: title, fileType: type, status: .pending)
        store.add(doc)
        selectedDoc = doc
    }
}

#Preview("Populated") {
    HomeView().environmentObject(DocumentStore.shared)
        .tint(Theme.accent)
}

#Preview("Empty") {
    let emptyStore = DocumentStore.shared
    HomeView().environmentObject(emptyStore)
        .tint(Theme.accent)
}
