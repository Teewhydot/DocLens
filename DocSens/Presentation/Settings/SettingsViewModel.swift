import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    private let repository: DocumentRepository
    private let fileImportService: FileImportService
    
    init(repository: DocumentRepository = CoreDataDocumentRepository(),
         fileImportService: FileImportService = LocalFileImportService()) {
        self.repository = repository
        self.fileImportService = fileImportService
    }
    
    func clearAllHistory() async {
        if let docs = try? await repository.getAllDocuments() {
            for doc in docs {
                if let saved = doc.savedFileName {
                    try? fileImportService.deleteFile(filename: saved)
                }
                try? await repository.deleteDocument(id: doc.id)
            }
        }
    }
}
