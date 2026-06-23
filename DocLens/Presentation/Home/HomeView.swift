import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct HomeView: View {
    @EnvironmentObject private var store: DocumentStore
    @State private var showImportOptions = false
    @State private var showFilePicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var pendingDeletion: DocumentEntity?
    @State private var selectedDoc: DocumentEntity?
    @State private var importError: String?
    @State private var showImportError = false

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
                Button("Import Image") {}  // triggered via PhotosPicker below
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete Document?", isPresented: deletionActiveBinding) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: {
                Text("This will permanently remove \"\(pendingDeletion?.title ?? "")\" and its analysis.")
            }
            .alert("Import Failed", isPresented: $showImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importError ?? "Could not read the file. Please try again.")
            }
            .fileImporter(isPresented: $showFilePicker,
                          allowedContentTypes: [.pdf],
                          allowsMultipleSelection: false) { result in
                handlePDFImport(result: result)
            }
            .photosPicker(isPresented: $showImportOptions.photosTrigger,
                          selection: $photoPickerItem,
                          matching: .images)
            .onChange(of: photoPickerItem) { _, item in
                guard let item else { return }
                handlePhotoImport(item: item)
            }
            .sheet(item: $selectedDoc) { doc in
                DocumentViewerView(document: doc)
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Document List

    private var documentList: some View {
        List {
            Section {
                ForEach(store.documents) { doc in
                    Button { selectedDoc = doc } label: { DocumentCell(document: doc) }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: Theme.rowHPadding, bottom: 4, trailing: Theme.rowHPadding))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { pendingDeletion = doc } label: {
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
            message: "Import a PDF contract or a photo of a document to analyze it privately on your device.",
            ctaTitle: "Import Document",
            action: { showImportOptions = true }
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label("Import Image", systemImage: "photo")
                }
                Button { showFilePicker = true } label: {
                    Label("Import PDF", systemImage: "doc.fill")
                }
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

    // MARK: - PDF Import

    private func handlePDFImport(result: Result<[URL], Error>) {
        switch result {
        case .failure(let err):
            importError = err.localizedDescription
            showImportError = true
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            do {
                let (_, filename) = try store.importFile(from: url, fileType: .pdf)
                let title = url.deletingPathExtension().lastPathComponent
                var doc = DocumentEntity(title: title, fileType: .pdf, savedFileName: filename)
                store.add(doc)
                doc = store.documents.first { $0.savedFileName == filename } ?? doc
                Task { await runAnalysis(for: doc) }
                selectedDoc = doc
            } catch {
                importError = error.localizedDescription
                showImportError = true
            }
        }
    }

    // MARK: - Photo Import

    private func handlePhotoImport(item: PhotosPickerItem) {
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { return }
                let filename = UUID().uuidString + ".jpg"
                let dest = DocumentStore.documentsFolder.appendingPathComponent(filename)
                try data.write(to: dest, options: .atomic)
                let title = "Image \(Date().formatted(.dateTime.month().day().hour().minute()))"
                var doc = DocumentEntity(title: title, fileType: .image, savedFileName: filename)
                await MainActor.run { store.add(doc) }
                doc = await MainActor.run { store.documents.first { $0.savedFileName == filename } ?? doc }
                await runAnalysis(for: doc)
                await MainActor.run { selectedDoc = doc }
            } catch {
                await MainActor.run {
                    importError = error.localizedDescription
                    showImportError = true
                }
            }
        }
        photoPickerItem = nil
    }

    // MARK: - Analysis pipeline

    private func runAnalysis(for doc: DocumentEntity) async {
        guard let fileURL = doc.resolvedFileURL else { return }
        // Mark as processing
        var processing = doc
        processing = DocumentEntity(id: doc.id, title: doc.title, importedAt: doc.importedAt,
                                    fileType: doc.fileType, savedFileName: doc.savedFileName,
                                    extractedText: "", detectedLanguage: "—",
                                    riskScore: 0, status: .processing)
        await MainActor.run { store.update(processing) }
        do {
            let result = try await AnalysisService.shared.analyze(url: fileURL, fileType: doc.fileType)
            let completed = DocumentEntity(id: doc.id, title: doc.title, importedAt: doc.importedAt,
                                           fileType: doc.fileType, savedFileName: doc.savedFileName,
                                           extractedText: result.extractedText,
                                           detectedLanguage: result.detectedLanguage,
                                           riskScore: result.riskScore, status: .complete)
            await MainActor.run {
                store.update(completed)
                store.setEntities(result.entities, for: doc.id)
                store.setFlags(result.flags, for: doc.id)
            }
        } catch {
            let failed = DocumentEntity(id: doc.id, title: doc.title, importedAt: doc.importedAt,
                                        fileType: doc.fileType, savedFileName: doc.savedFileName,
                                        extractedText: "", detectedLanguage: "—",
                                        riskScore: 0, status: .failed)
            await MainActor.run {
                store.update(failed)
                importError = error.localizedDescription
                showImportError = true
            }
        }
    }
}

// MARK: - Binding extension for PhotosPicker trigger

private extension Binding where Value == Bool {
    /// Unused — photos picker is driven directly via toolbar Menu.
    var photosTrigger: Binding<Bool> { self }
}

#Preview("Populated") {
    HomeView().environmentObject(SampleData.makePreviewStore())
        .tint(Theme.accent)
}

#Preview("Empty") {
    HomeView().environmentObject(DocumentStore.shared)
        .tint(Theme.accent)
}
