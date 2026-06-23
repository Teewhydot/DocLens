import Foundation
import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var documents: [DocumentEntity] = []
    
    private let repository: DocumentRepository
    
    init(repository: DocumentRepository = CoreDataDocumentRepository()) {
        self.repository = repository
    }
    
    func fetchDocuments() async {
        if let docs = try? await repository.getAllDocuments() {
            self.documents = docs
        }
    }
}
