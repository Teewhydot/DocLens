import Foundation
import SwiftUI

@MainActor
final class DocumentViewerViewModel: ObservableObject {
    @Published var document: DocumentEntity
    @Published var isAnalyzing = false
    @Published var analysisError: String?
    @Published var showError = false
    @Published var showResults = false
    
    private let analyzeDocumentUseCase: AnalyzeDocumentUseCase
    private let documentRepository: DocumentRepository
    
    init(document: DocumentEntity,
         analyzeDocumentUseCase: AnalyzeDocumentUseCase = AnalyzeDocumentUseCaseImpl(
            documentRepository: CoreDataDocumentRepository(),
            notificationService: LocalNotificationService()
         ),
         documentRepository: DocumentRepository = CoreDataDocumentRepository()) {
        self.document = document
        self.analyzeDocumentUseCase = analyzeDocumentUseCase
        self.documentRepository = documentRepository
    }
    
    func refreshDocument() async {
        if let updated = try? await documentRepository.getDocument(id: document.id) {
            self.document = updated
            if updated.status == .complete {
                // Keep showResults in sync if needed, but usually triggered by user
            }
        }
    }
    
    func runAnalysis() {
        guard document.resolvedFileURL != nil else { return }
        isAnalyzing = true
        analysisError = nil
        
        Task {
            do {
                try await analyzeDocumentUseCase.execute(documentId: document.id)
                await refreshDocument()
                self.isAnalyzing = false
                self.showResults = true
            } catch {
                self.isAnalyzing = false
                self.analysisError = error.localizedDescription
                self.showError = true
                await refreshDocument()
            }
        }
    }
}
