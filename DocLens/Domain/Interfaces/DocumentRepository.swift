import Foundation

/// Repository interface for saving and retrieving document data.
protocol DocumentRepository: Sendable {
    func getDocument(id: UUID) async throws -> DocumentEntity?
    func saveDocument(_ document: DocumentEntity) async throws
    func deleteDocument(id: UUID) async throws
    func getAllDocuments() async throws -> [DocumentEntity]
    
    func getEntities(for documentId: UUID) async throws -> [EntityMentionEntity]
    func saveEntities(_ entities: [EntityMentionEntity], for documentId: UUID) async throws
    
    func getRiskFlags(for documentId: UUID) async throws -> [RiskFlagEntity]
    func saveRiskFlags(_ flags: [RiskFlagEntity], for documentId: UUID) async throws
}
