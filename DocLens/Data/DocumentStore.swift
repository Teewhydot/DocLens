import Foundation
import Combine

/// In-memory shared document store. Acts as the single source of truth
/// until Core Data + CloudKit is wired in.
@MainActor
final class DocumentStore: ObservableObject {
    static let shared = DocumentStore()

    @Published var documents: [DocumentEntity] = SampleData.documents
    @Published var entityMentions: [UUID: [EntityMentionEntity]] = SampleData.entityMentions
    @Published var riskFlags: [UUID: [RiskFlagEntity]] = SampleData.riskFlags

    private init() {}

    // MARK: - CRUD

    func add(_ document: DocumentEntity) {
        documents.insert(document, at: 0)
    }

    func update(_ document: DocumentEntity) {
        guard let idx = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[idx] = document
    }

    func delete(_ document: DocumentEntity) {
        documents.removeAll { $0.id == document.id }
        entityMentions.removeValue(forKey: document.id)
        riskFlags.removeValue(forKey: document.id)
    }

    func setEntities(_ entities: [EntityMentionEntity], for docId: UUID) {
        entityMentions[docId] = entities
    }

    func setFlags(_ flags: [RiskFlagEntity], for docId: UUID) {
        riskFlags[docId] = flags
    }

    func entities(for docId: UUID) -> [EntityMentionEntity] {
        entityMentions[docId] ?? []
    }

    func flags(for docId: UUID) -> [RiskFlagEntity] {
        riskFlags[docId] ?? []
    }

    func clearAll() {
        documents = []
        entityMentions = [:]
        riskFlags = [:]
    }
}
