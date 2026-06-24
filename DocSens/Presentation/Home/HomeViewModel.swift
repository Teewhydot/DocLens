import Foundation
import SwiftUI
import Combine
import CoreData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var documents: [DocumentEntity] = []
    
    private let repository: DocumentRepository
    private let fileImportService: FileImportService
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: DocumentRepository = CoreDataDocumentRepository(),
         fileImportService: FileImportService = LocalFileImportService()) {
        self.repository = repository
        self.fileImportService = fileImportService
        
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.fetchDocuments()
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchDocuments() async {
        if let docs = try? await repository.getAllDocuments() {
            self.documents = docs
        }
    }
    
    func deleteDocument(_ document: DocumentEntity) async {
        if let filename = document.savedFileName {
            try? fileImportService.deleteFile(filename: filename)
        }
        try? await repository.deleteDocument(id: document.id)
        await fetchDocuments()
    }
    
    func importDocument(from url: URL, type: FileType) async throws -> DocumentEntity {
        let (_, filename) = try fileImportService.importFile(from: url, fileType: type)
        let newDoc = DocumentEntity(
            title: url.lastPathComponent,
            fileType: type,
            savedFileName: filename
        )
        try await repository.saveDocument(newDoc)
        await fetchDocuments()
        return newDoc
    }
}
