import Foundation
import Combine

/// Persistent document store. Persists documents, entities, and flags to JSON files
/// inside the app's Documents/DocLens/ sandbox folder.
@MainActor
final class DocumentStore: ObservableObject {
    static let shared = DocumentStore()

    @Published var documents: [DocumentEntity] = []
    @Published var entityMentions: [UUID: [EntityMentionEntity]] = [:]
    @Published var riskFlags: [UUID: [RiskFlagEntity]] = [:]

    // MARK: - Sandbox paths

    static let documentsFolder: URL = {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("DocLens", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()

    private static let docsIndex    = documentsFolder.appendingPathComponent("_documents.json")
    private static let entitiesIndex = documentsFolder.appendingPathComponent("_entities.json")
    private static let flagsIndex    = documentsFolder.appendingPathComponent("_flags.json")

    // MARK: - Init

    private init() {
        load()
    }

    // MARK: - CRUD

    func add(_ document: DocumentEntity) {
        documents.insert(document, at: 0)
        save()
    }

    func update(_ document: DocumentEntity) {
        guard let idx = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[idx] = document
        save()
    }

    func delete(_ document: DocumentEntity) {
        // Remove saved file from sandbox
        if let url = document.resolvedFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        documents.removeAll { $0.id == document.id }
        entityMentions.removeValue(forKey: document.id)
        riskFlags.removeValue(forKey: document.id)
        save()
    }

    func setEntities(_ entities: [EntityMentionEntity], for docId: UUID) {
        entityMentions[docId] = entities
        save()
    }

    func setFlags(_ flags: [RiskFlagEntity], for docId: UUID) {
        riskFlags[docId] = flags
        save()
    }

    func entities(for docId: UUID) -> [EntityMentionEntity] {
        entityMentions[docId] ?? []
    }

    func flags(for docId: UUID) -> [RiskFlagEntity] {
        riskFlags[docId] ?? []
    }

    func clearAll() {
        // Delete all saved files
        for doc in documents {
            if let url = doc.resolvedFileURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
        documents = []
        entityMentions = [:]
        riskFlags = [:]
        save()
    }

    // MARK: - File import helper

    /// Copies `sourceURL` into the sandbox and returns the new URL + filename.
    /// Call startAccessing/stopAccessing around this if needed.
    func importFile(from sourceURL: URL, fileType: FileType) throws -> (URL, String) {
        let ext = sourceURL.pathExtension.isEmpty
            ? (fileType == .pdf ? "pdf" : "jpg")
            : sourceURL.pathExtension
        let filename = UUID().uuidString + "." + ext
        let dest = Self.documentsFolder.appendingPathComponent(filename)
        try FileManager.default.copyItem(at: sourceURL, to: dest)
        return (dest, filename)
    }

    // MARK: - Persistence

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(documents) {
            try? data.write(to: Self.docsIndex, options: .atomic)
        }
        // Entities: encode as array of CodableEntityBag
        let entityBags = entityMentions.map { CodableBag(id: $0.key, items: $0.value) }
        if let data = try? encoder.encode(entityBags) {
            try? data.write(to: Self.entitiesIndex, options: .atomic)
        }
        let flagBags = riskFlags.map { CodableBag(id: $0.key, items: $0.value) }
        if let data = try? encoder.encode(flagBags) {
            try? data.write(to: Self.flagsIndex, options: .atomic)
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: Self.docsIndex),
           let docs = try? decoder.decode([DocumentEntity].self, from: data) {
            documents = docs
        }
        if let data = try? Data(contentsOf: Self.entitiesIndex),
           let bags = try? decoder.decode([CodableBag<EntityMentionEntity>].self, from: data) {
            entityMentions = Dictionary(uniqueKeysWithValues: bags.map { ($0.id, $0.items) })
        }
        if let data = try? Data(contentsOf: Self.flagsIndex),
           let bags = try? decoder.decode([CodableBag<RiskFlagEntity>].self, from: data) {
            riskFlags = Dictionary(uniqueKeysWithValues: bags.map { ($0.id, $0.items) })
        }
    }
}

// MARK: - Helper for encoding dictionaries as arrays

private struct CodableBag<T: Codable>: Codable {
    let id: UUID
    let items: [T]
}
