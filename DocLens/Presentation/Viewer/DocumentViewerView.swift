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
    @StateObject private var viewModel: DocumentViewerViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("autoAnalyzeOnImport") private var autoAnalyze = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true

    init(document: DocumentEntity) {
        _viewModel = StateObject(wrappedValue: DocumentViewerViewModel(document: document))
    }

    private var currentDoc: DocumentEntity {
        viewModel.document
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                contentView
            }
            .navigationTitle(currentDoc.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .sheet(isPresented: $viewModel.showResults) {
                AnalysisResultsView(document: currentDoc)
            }
            .alert("Analysis Failed", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.analysisError ?? "An unknown error occurred.")
            }
            .task {
                await viewModel.refreshDocument()
                if autoAnalyze && currentDoc.status == .pending && !viewModel.isAnalyzing {
                    viewModel.runAnalysis()
                }
            }
            .sensoryFeedback(.success, trigger: viewModel.showResults) { _, newValue in
                return hapticFeedback && newValue
            }
            .sensoryFeedback(.error, trigger: viewModel.showError) { _, newValue in
                return hapticFeedback && newValue
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
            Button { viewModel.showResults = true } label: {
                Label("Analysis", systemImage: "chart.bar.doc.horizontal")
            }
            .tint(Theme.accent)
        } else if doc.status == .processing || viewModel.isAnalyzing {
            ProgressView().tint(Theme.accent)
        } else if doc.resolvedFileURL != nil && doc.status != .complete {
            Button { viewModel.runAnalysis() } label: {
                Label("Analyze", systemImage: "sparkles")
            }
            .tint(Theme.accent)
        }
    }

    // MARK: - Analysis

    // Logic moved to DocumentViewerViewModel
}
