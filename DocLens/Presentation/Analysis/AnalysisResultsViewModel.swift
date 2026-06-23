import Foundation
import SwiftUI

@MainActor
final class AnalysisResultsViewModel: ObservableObject {
    @Published var document: DocumentEntity
    @Published var flags: [RiskFlagEntity] = []
    @Published var entities: [EntityMentionEntity] = []
    
    private let repository: DocumentRepository
    
    init(document: DocumentEntity, repository: DocumentRepository = CoreDataDocumentRepository()) {
        self.document = document
        self.repository = repository
    }
    
    func fetchData() async {
        if let docsFlags = try? await repository.getRiskFlags(for: document.id) {
            self.flags = docsFlags
        }
        if let docsEntities = try? await repository.getEntities(for: document.id) {
            self.entities = docsEntities
        }
    }
}
