import SwiftUI
import PDFKit
import UIKit

// MARK: - PDF UIViewRepresentable

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor(Theme.background)
        if let doc = PDFDocument(url: url) {
            pdfView.document = doc
        }
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Main Viewer

struct DocumentViewerView: View {
    let document: DocumentEntity

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DocumentStore
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var showResults = false
    @State private var showError = false

    private var currentDoc: DocumentEntity {
        store.documents.first { $0.id == document.id } ?? document
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                contentView
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showResults) {
                AnalysisResultsView(document: currentDoc)
                    .environmentObject(store)
            }
            .alert("Analysis Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(analysisError ?? "An unknown error occurred.")
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if let url = currentDoc.resolvedFileURL {
            fileContentView(url: url)
        } else {
            noFileView
        }
    }

    @ViewBuilder
    private func fileContentView(url: URL) -> some View {
        if currentDoc.fileType == .pdf {
            PDFKitView(url: url).ignoresSafeArea(edges: .bottom)
        } else {
            ScrollView([.vertical, .horizontal]) {
                if let img = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
            }
        }
    }

    private var noFileView: some View {
        VStack(spacing: 24) {
            Image(systemName: currentDoc.fileType == .pdf ? "doc.richtext" : "photo.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)
            Text(currentDoc.title)
                .font(.docHeadline())
                .multilineTextAlignment(.center)
            Text("The file could not be found.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            trailingToolbarItem
        }
        ToolbarItem(placement: .topBarLeading) {
            Button("Done") { dismiss() }
        }
    }

    @ViewBuilder
    private var trailingToolbarItem: some View {
        let doc = currentDoc
        if doc.status == .complete {
            Button { showResults = true } label: {
                Label("Analysis", systemImage: "chart.bar.doc.horizontal")
            }
            .tint(Theme.accent)
        } else if doc.status == .processing || isAnalyzing {
            ProgressView().tint(Theme.accent)
        } else if doc.resolvedFileURL != nil && doc.status != .complete {
            Button { runAnalysis() } label: {
                Label("Analyze", systemImage: "sparkles")
            }
            .tint(Theme.accent)
        }
    }

    // MARK: - Analysis

    private func runAnalysis() {
        guard let url = currentDoc.resolvedFileURL else { return }
        isAnalyzing = true
        let docSnapshot = currentDoc
        let processing = DocumentEntity(id: docSnapshot.id, title: docSnapshot.title,
                                         importedAt: docSnapshot.importedAt, fileType: docSnapshot.fileType,
                                         savedFileName: docSnapshot.savedFileName, extractedText: "",
                                         detectedLanguage: "—", riskScore: 0, status: .processing)
        store.update(processing)
        Task {
            do {
                let result = try await AnalysisService.shared.analyze(url: url, fileType: docSnapshot.fileType)
                let completed = DocumentEntity(id: docSnapshot.id, title: docSnapshot.title,
                                               importedAt: docSnapshot.importedAt, fileType: docSnapshot.fileType,
                                               savedFileName: docSnapshot.savedFileName,
                                               extractedText: result.extractedText,
                                               detectedLanguage: result.detectedLanguage,
                                               riskScore: result.riskScore, status: .complete)
                await MainActor.run {
                    store.update(completed)
                    store.setEntities(result.entities, for: docSnapshot.id)
                    store.setFlags(result.flags, for: docSnapshot.id)
                    isAnalyzing = false
                    showResults = true
                }
            } catch {
                await MainActor.run {
                    analysisError = error.localizedDescription
                    showError = true
                    isAnalyzing = false
                    let failed = DocumentEntity(id: docSnapshot.id, title: docSnapshot.title,
                                                importedAt: docSnapshot.importedAt, fileType: docSnapshot.fileType,
                                                savedFileName: docSnapshot.savedFileName, extractedText: "",
                                                detectedLanguage: "—", riskScore: 0, status: .failed)
                    store.update(failed)
                }
            }
        }
    }
}
