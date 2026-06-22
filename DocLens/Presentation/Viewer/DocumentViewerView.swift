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
    let fileURL: URL?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DocumentStore
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var showResults = false
    @State private var showError = false

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

    private var currentDoc: DocumentEntity {
        store.documents.first { $0.id == document.id } ?? document
    }

    @ViewBuilder
    private var contentView: some View {
        if let url = fileURL {
            fileContentView(url: url)
        } else {
            samplePreview
        }
    }

    @ViewBuilder
    private func fileContentView(url: URL) -> some View {
        if document.fileType == .pdf {
            PDFKitView(url: url).ignoresSafeArea(edges: .bottom)
        } else {
            imageViewer(url: url)
        }
    }

    private func imageViewer(url: URL) -> some View {
        ScrollView([.vertical, .horizontal]) {
            if let img = UIImage(contentsOfFile: url.path) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
        }
    }

    private var samplePreview: some View {
        VStack(spacing: 24) {
            Image(systemName: document.fileType == .pdf ? "doc.richtext" : "photo.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)
            Text(document.title)
                .font(.docHeadline())
                .multilineTextAlignment(.center)
            Text("Document preview is shown after import.\nThis is a sample document.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if document.status == .complete {
                analyzeButton
            }
        }
        .padding(32)
    }

    private var analyzeButton: some View {
        Button {
            showResults = true
        } label: {
            Label("View Analysis", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .padding(.horizontal, 32)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if document.status == .complete {
                Button {
                    showResults = true
                } label: {
                    Label("Analysis", systemImage: "chart.bar.doc.horizontal")
                }
                .tint(Theme.accent)
            } else if document.status == .processing || isAnalyzing {
                ProgressView()
                    .tint(Theme.accent)
            } else if let url = fileURL {
                Button {
                    runAnalysis(url: url)
                } label: {
                    Label("Analyze", systemImage: "sparkles")
                }
                .tint(Theme.accent)
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button("Done") { dismiss() }
        }
    }

    private func runAnalysis(url: URL) {
        isAnalyzing = true
        // Mark as processing
        var updated = document
        updated = DocumentEntity(id: document.id, title: document.title, importedAt: document.importedAt,
                                  fileType: document.fileType, extractedText: document.extractedText,
                                  detectedLanguage: document.detectedLanguage, riskScore: document.riskScore,
                                  status: .processing)
        store.update(updated)

        Task {
            do {
                let result = try await AnalysisService.shared.analyze(url: url, fileType: document.fileType)
                await MainActor.run {
                    let finalDoc = DocumentEntity(
                        id: document.id, title: document.title, importedAt: document.importedAt,
                        fileType: document.fileType, extractedText: result.extractedText,
                        detectedLanguage: result.detectedLanguage, riskScore: result.riskScore, status: .complete
                    )
                    store.update(finalDoc)
                    store.setEntities(result.entities, for: document.id)
                    store.setFlags(result.flags, for: document.id)
                    isAnalyzing = false
                    showResults = true
                }
            } catch {
                await MainActor.run {
                    analysisError = error.localizedDescription
                    showError = true
                    isAnalyzing = false
                    let failedDoc = DocumentEntity(id: document.id, title: document.title, importedAt: document.importedAt,
                                                    fileType: document.fileType, extractedText: "",
                                                    detectedLanguage: document.detectedLanguage, riskScore: 0, status: .failed)
                    store.update(failedDoc)
                }
            }
        }
    }
}
