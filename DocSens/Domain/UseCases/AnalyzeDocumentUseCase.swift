import Foundation

protocol AnalyzeDocumentUseCase: Sendable {
    func execute(documentId: UUID) async throws
}

final class AnalyzeDocumentUseCaseImpl: AnalyzeDocumentUseCase {
    private let documentRepository: DocumentRepository
    private let notificationService: NotificationService
    
    init(documentRepository: DocumentRepository, notificationService: NotificationService) {
        self.documentRepository = documentRepository
        self.notificationService = notificationService
    }
    
    func execute(documentId: UUID) async throws {
        // 1. Fetch document
        guard var document = try await documentRepository.getDocument(id: documentId) else {
            throw AnalyzeDocumentError.documentNotFound
        }
        
        guard let fileURL = document.resolvedFileURL else {
            throw AnalyzeDocumentError.fileURLNotFound
        }
        
        // 2. Mark as processing
        document.status = .processing
        try await documentRepository.saveDocument(document)
        
        do {
            // 3. Analyze via the existing AnalysisService
            // AnalysisService is an actor, we can call it securely
            let result = try await AnalysisService.shared.analyze(url: fileURL, fileType: document.fileType)
            
            // 4. Update document with analysis results
            document.extractedText = result.extractedText
            document.detectedLanguage = result.detectedLanguage
            document.riskScore = result.riskScore
            document.status = .complete
            
            // 5. Save all to Core Data
            try await documentRepository.saveDocument(document)
            try await documentRepository.saveEntities(result.entities, for: documentId)
            try await documentRepository.saveRiskFlags(result.flags, for: documentId)
            
            // 6. Trigger a local push notification
            let title = "DocSens Analysis Complete"
            let body = "Finished analyzing \"\(document.title)\"."
            // Ignore errors for notification scheduling
            try? await notificationService.scheduleLocalNotification(title: title, body: body)
            
        } catch {
            // Revert status on failure
            document.status = .failed
            try await documentRepository.saveDocument(document)
            throw error
        }
    }
}

enum AnalyzeDocumentError: LocalizedError {
    case documentNotFound
    case fileURLNotFound
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound: return "The document was not found."
        case .fileURLNotFound: return "The file associated with this document could not be located."
        }
    }
}
