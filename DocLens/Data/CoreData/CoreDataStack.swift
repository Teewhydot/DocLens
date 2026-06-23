import Foundation
import CoreData

final class CoreDataStack: Sendable {
    static let shared = CoreDataStack()
    
    let container: NSPersistentCloudKitContainer
    
    private init() {
        let model = Self.createManagedObjectModel()
        container = NSPersistentCloudKitContainer(name: "DocLens", managedObjectModel: model)
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No Descriptions found")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // DocumentRecord
        let docEntity = NSEntityDescription()
        docEntity.name = "DocumentRecord"
        docEntity.managedObjectClassName = "NSManagedObject"
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.isOptional = false
        
        let importedAtAttr = NSAttributeDescription()
        importedAtAttr.name = "importedAt"
        importedAtAttr.attributeType = .dateAttributeType
        importedAtAttr.isOptional = false
        
        let fileTypeAttr = NSAttributeDescription()
        fileTypeAttr.name = "fileType"
        fileTypeAttr.attributeType = .stringAttributeType
        fileTypeAttr.isOptional = false
        
        let savedFileNameAttr = NSAttributeDescription()
        savedFileNameAttr.name = "savedFileName"
        savedFileNameAttr.attributeType = .stringAttributeType
        savedFileNameAttr.isOptional = true
        
        let extractedTextAttr = NSAttributeDescription()
        extractedTextAttr.name = "extractedText"
        extractedTextAttr.attributeType = .stringAttributeType
        extractedTextAttr.isOptional = false
        
        let detectedLanguageAttr = NSAttributeDescription()
        detectedLanguageAttr.name = "detectedLanguage"
        detectedLanguageAttr.attributeType = .stringAttributeType
        detectedLanguageAttr.isOptional = false
        
        let riskScoreAttr = NSAttributeDescription()
        riskScoreAttr.name = "riskScore"
        riskScoreAttr.attributeType = .doubleAttributeType
        riskScoreAttr.isOptional = false
        
        let statusAttr = NSAttributeDescription()
        statusAttr.name = "status"
        statusAttr.attributeType = .stringAttributeType
        statusAttr.isOptional = false
        
        // EntityMention
        let mentionEntity = NSEntityDescription()
        mentionEntity.name = "EntityMention"
        mentionEntity.managedObjectClassName = "NSManagedObject"
        
        let mIdAttr = NSAttributeDescription()
        mIdAttr.name = "id"
        mIdAttr.attributeType = .UUIDAttributeType
        mIdAttr.isOptional = false
        
        let mTypeAttr = NSAttributeDescription()
        mTypeAttr.name = "type"
        mTypeAttr.attributeType = .stringAttributeType
        mTypeAttr.isOptional = false
        
        let mValueAttr = NSAttributeDescription()
        mValueAttr.name = "value"
        mValueAttr.attributeType = .stringAttributeType
        mValueAttr.isOptional = false
        
        let mConfAttr = NSAttributeDescription()
        mConfAttr.name = "confidence"
        mConfAttr.attributeType = .doubleAttributeType
        mConfAttr.isOptional = false
        
        // RiskFlag
        let flagEntity = NSEntityDescription()
        flagEntity.name = "RiskFlag"
        flagEntity.managedObjectClassName = "NSManagedObject"
        
        let fIdAttr = NSAttributeDescription()
        fIdAttr.name = "id"
        fIdAttr.attributeType = .UUIDAttributeType
        fIdAttr.isOptional = false
        
        let fKeywordAttr = NSAttributeDescription()
        fKeywordAttr.name = "keyword"
        fKeywordAttr.attributeType = .stringAttributeType
        fKeywordAttr.isOptional = false
        
        let fCatAttr = NSAttributeDescription()
        fCatAttr.name = "category"
        fCatAttr.attributeType = .stringAttributeType
        fCatAttr.isOptional = false
        
        let fSevAttr = NSAttributeDescription()
        fSevAttr.name = "severity"
        fSevAttr.attributeType = .stringAttributeType
        fSevAttr.isOptional = false
        
        let fContextAttr = NSAttributeDescription()
        fContextAttr.name = "excerptContext"
        fContextAttr.attributeType = .stringAttributeType
        fContextAttr.isOptional = false
        
        // Relationships
        let docToMentions = NSRelationshipDescription()
        docToMentions.name = "mentions"
        docToMentions.destinationEntity = mentionEntity
        docToMentions.minCount = 0
        docToMentions.maxCount = 0 // to-many
        docToMentions.deleteRule = .cascadeDeleteRule
        
        let mentionToDoc = NSRelationshipDescription()
        mentionToDoc.name = "document"
        mentionToDoc.destinationEntity = docEntity
        mentionToDoc.minCount = 1
        mentionToDoc.maxCount = 1 // to-one
        mentionToDoc.deleteRule = .nullifyDeleteRule
        
        docToMentions.inverseRelationship = mentionToDoc
        mentionToDoc.inverseRelationship = docToMentions
        
        let docToFlags = NSRelationshipDescription()
        docToFlags.name = "flags"
        docToFlags.destinationEntity = flagEntity
        docToFlags.minCount = 0
        docToFlags.maxCount = 0 // to-many
        docToFlags.deleteRule = .cascadeDeleteRule
        
        let flagToDoc = NSRelationshipDescription()
        flagToDoc.name = "document"
        flagToDoc.destinationEntity = docEntity
        flagToDoc.minCount = 1
        flagToDoc.maxCount = 1 // to-one
        flagToDoc.deleteRule = .nullifyDeleteRule
        
        docToFlags.inverseRelationship = flagToDoc
        flagToDoc.inverseRelationship = docToFlags
        
        docEntity.properties = [idAttr, titleAttr, importedAtAttr, fileTypeAttr, savedFileNameAttr, extractedTextAttr, detectedLanguageAttr, riskScoreAttr, statusAttr, docToMentions, docToFlags]
        mentionEntity.properties = [mIdAttr, mTypeAttr, mValueAttr, mConfAttr, mentionToDoc]
        flagEntity.properties = [fIdAttr, fKeywordAttr, fCatAttr, fSevAttr, fContextAttr, flagToDoc]
        
        model.entities = [docEntity, mentionEntity, flagEntity]
        return model
    }
    
    func saveContext() throws {
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
        }
    }
}
