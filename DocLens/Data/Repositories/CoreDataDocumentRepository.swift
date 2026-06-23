import Foundation
import CoreData

final class CoreDataDocumentRepository: DocumentRepository, @unchecked Sendable {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }
    
    func getDocument(id: UUID) async throws -> DocumentEntity? {
        return try await context.perform {
            if let managedDoc = try self.fetchDocument(id: id) {
                return self.mapToEntity(managedDoc)
            }
            return nil
        }
    }
    
    func saveDocument(_ document: DocumentEntity) async throws {
        try await context.perform {
            let managedDoc: NSManagedObject
            if let existing = try self.fetchDocument(id: document.id) {
                managedDoc = existing
            } else {
                guard let entityDesc = NSEntityDescription.entity(forEntityName: "DocumentRecord", in: self.context) else { return }
                managedDoc = NSManagedObject(entity: entityDesc, insertInto: self.context)
            }
            
            managedDoc.setValue(document.id, forKey: "id")
            managedDoc.setValue(document.title, forKey: "title")
            managedDoc.setValue(document.importedAt, forKey: "importedAt")
            managedDoc.setValue(document.fileType.rawValue, forKey: "fileType")
            managedDoc.setValue(document.savedFileName, forKey: "savedFileName")
            managedDoc.setValue(document.extractedText, forKey: "extractedText")
            managedDoc.setValue(document.detectedLanguage, forKey: "detectedLanguage")
            managedDoc.setValue(document.riskScore, forKey: "riskScore")
            managedDoc.setValue(document.status.rawValue, forKey: "status")
            
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }
    
    func deleteDocument(id: UUID) async throws {
        try await context.perform {
            if let managedDoc = try self.fetchDocument(id: id) {
                self.context.delete(managedDoc)
                if self.context.hasChanges {
                    try self.context.save()
                }
            }
        }
    }
    
    func getAllDocuments() async throws -> [DocumentEntity] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "DocumentRecord")
            request.sortDescriptors = [NSSortDescriptor(key: "importedAt", ascending: false)]
            let results = try self.context.fetch(request)
            return results.map { self.mapToEntity($0) }
        }
    }
    
    func getEntities(for documentId: UUID) async throws -> [EntityMentionEntity] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "EntityMention")
            request.predicate = NSPredicate(format: "document.id == %@", documentId as CVarArg)
            let results = try self.context.fetch(request)
            return results.map { self.mapToMentionEntity($0) }
        }
    }
    
    func saveEntities(_ entities: [EntityMentionEntity], for documentId: UUID) async throws {
        try await context.perform {
            guard let managedDoc = try self.fetchDocument(id: documentId) else { return }
            
            // Delete old mentions
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "EntityMention")
            fetchRequest.predicate = NSPredicate(format: "document.id == %@", documentId as CVarArg)
            let oldMentions = try self.context.fetch(fetchRequest)
            for m in oldMentions { self.context.delete(m) }
            
            // Insert new ones
            for entity in entities {
                guard let desc = NSEntityDescription.entity(forEntityName: "EntityMention", in: self.context) else { continue }
                let managedMention = NSManagedObject(entity: desc, insertInto: self.context)
                managedMention.setValue(entity.id, forKey: "id")
                managedMention.setValue(entity.type.rawValue, forKey: "type")
                managedMention.setValue(entity.value, forKey: "value")
                managedMention.setValue(entity.confidence, forKey: "confidence")
                managedMention.setValue(managedDoc, forKey: "document")
            }
            
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }
    
    func getRiskFlags(for documentId: UUID) async throws -> [RiskFlagEntity] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "RiskFlag")
            request.predicate = NSPredicate(format: "document.id == %@", documentId as CVarArg)
            let results = try self.context.fetch(request)
            return results.map { self.mapToFlagEntity($0) }
        }
    }
    
    func saveRiskFlags(_ flags: [RiskFlagEntity], for documentId: UUID) async throws {
        try await context.perform {
            guard let managedDoc = try self.fetchDocument(id: documentId) else { return }
            
            // Delete old flags
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "RiskFlag")
            fetchRequest.predicate = NSPredicate(format: "document.id == %@", documentId as CVarArg)
            let oldFlags = try self.context.fetch(fetchRequest)
            for f in oldFlags { self.context.delete(f) }
            
            // Insert new ones
            for flag in flags {
                guard let desc = NSEntityDescription.entity(forEntityName: "RiskFlag", in: self.context) else { continue }
                let managedFlag = NSManagedObject(entity: desc, insertInto: self.context)
                managedFlag.setValue(flag.id, forKey: "id")
                managedFlag.setValue(flag.keyword, forKey: "keyword")
                managedFlag.setValue(flag.category.rawValue, forKey: "category")
                managedFlag.setValue(flag.severity.rawValue, forKey: "severity")
                managedFlag.setValue(flag.excerptContext, forKey: "excerptContext")
                managedFlag.setValue(managedDoc, forKey: "document")
            }
            
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func fetchDocument(id: UUID) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "DocumentRecord")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    private func mapToEntity(_ mo: NSManagedObject) -> DocumentEntity {
        let id = mo.value(forKey: "id") as? UUID ?? UUID()
        let title = mo.value(forKey: "title") as? String ?? "Untitled"
        let importedAt = mo.value(forKey: "importedAt") as? Date ?? Date()
        let fileTypeRaw = mo.value(forKey: "fileType") as? String ?? "pdf"
        let savedFileName = mo.value(forKey: "savedFileName") as? String
        let extractedText = mo.value(forKey: "extractedText") as? String ?? ""
        let detectedLanguage = mo.value(forKey: "detectedLanguage") as? String ?? "—"
        let riskScore = mo.value(forKey: "riskScore") as? Double ?? 0.0
        let statusRaw = mo.value(forKey: "status") as? String ?? "pending"
        
        return DocumentEntity(
            id: id,
            title: title,
            importedAt: importedAt,
            fileType: FileType(rawValue: fileTypeRaw) ?? .pdf,
            savedFileName: savedFileName,
            extractedText: extractedText,
            detectedLanguage: detectedLanguage,
            riskScore: riskScore,
            status: AnalysisStatus(rawValue: statusRaw) ?? .pending
        )
    }
    
    private func mapToMentionEntity(_ mo: NSManagedObject) -> EntityMentionEntity {
        let id = mo.value(forKey: "id") as? UUID ?? UUID()
        let typeRaw = mo.value(forKey: "type") as? String ?? "person"
        let value = mo.value(forKey: "value") as? String ?? ""
        let conf = mo.value(forKey: "confidence") as? Double ?? 1.0
        return EntityMentionEntity(id: id, type: EntityType(rawValue: typeRaw) ?? .person, value: value, confidence: conf)
    }
    
    private func mapToFlagEntity(_ mo: NSManagedObject) -> RiskFlagEntity {
        let id = mo.value(forKey: "id") as? UUID ?? UUID()
        let keyword = mo.value(forKey: "keyword") as? String ?? ""
        let catRaw = mo.value(forKey: "category") as? String ?? "liability"
        let sevRaw = mo.value(forKey: "severity") as? String ?? "medium"
        let context = mo.value(forKey: "excerptContext") as? String ?? ""
        
        return RiskFlagEntity(
            id: id,
            keyword: keyword,
            category: RiskCategory(rawValue: catRaw) ?? .liability,
            severity: RiskSeverity(rawValue: sevRaw) ?? .medium,
            excerptContext: context
        )
    }
}
