import Foundation
@testable import DocSens

final class MockDocumentRepository: DocumentRepository {
    var documentToReturn: DocumentEntity?
    var savedDocuments: [DocumentEntity] = []

    var entitiesToReturn: [EntityMentionEntity] = []
    var savedEntities: [EntityMentionEntity] = []

    var flagsToReturn: [RiskFlagEntity] = []
    var savedFlags: [RiskFlagEntity] = []

    func getDocument(id: UUID) async throws -> DocumentEntity? {
        return documentToReturn
    }

    func saveDocument(_ document: DocumentEntity) async throws {
        savedDocuments.append(document)
    }

    func deleteDocument(id: UUID) async throws {
        // Not used in execute
    }

    func getAllDocuments() async throws -> [DocumentEntity] {
        return [] // Not used in execute
    }

    func getEntities(for documentId: UUID) async throws -> [EntityMentionEntity] {
        return entitiesToReturn
    }

    func saveEntities(_ entities: [EntityMentionEntity], for documentId: UUID) async throws {
        savedEntities.append(contentsOf: entities)
    }

    func getRiskFlags(for documentId: UUID) async throws -> [RiskFlagEntity] {
        return flagsToReturn
    }

    func saveRiskFlags(_ flags: [RiskFlagEntity], for documentId: UUID) async throws {
        savedFlags.append(contentsOf: flags)
    }
}

final class MockNotificationService: NotificationService {
    var requestedAuthorization = false
    var authorizationResult = true
    var scheduledNotifications: [(title: String, body: String)] = []

    func requestAuthorization() async throws -> Bool {
        requestedAuthorization = true
        return authorizationResult
    }

    func scheduleLocalNotification(title: String, body: String) async throws {
        scheduledNotifications.append((title: title, body: body))
    }
}

// Minimal mock/stub for XCTest behavior to run locally via swift script
import XCTest

final class AnalyzeDocumentUseCaseTests: XCTestCase {

    var mockRepository: MockDocumentRepository!
    var mockNotificationService: MockNotificationService!
    var sut: AnalyzeDocumentUseCaseImpl!

    override func setUp() {
        super.setUp()
        mockRepository = MockDocumentRepository()
        mockNotificationService = MockNotificationService()
        sut = AnalyzeDocumentUseCaseImpl(documentRepository: mockRepository, notificationService: mockNotificationService)
    }

    override func tearDown() {
        sut = nil
        mockNotificationService = nil
        mockRepository = nil
        super.tearDown()
    }

    func testExecute_DocumentNotFound_ThrowsError() async {
        let documentId = UUID()
        mockRepository.documentToReturn = nil

        do {
            try await sut.execute(documentId: documentId)
            XCTFail("Expected documentNotFound error, but execution succeeded")
        } catch let error as AnalyzeDocumentError {
            XCTAssertEqual(error, .documentNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecute_FileURLNotFound_ThrowsError() async {
        let documentId = UUID()
        let document = DocumentEntity(id: documentId, title: "Test Doc", savedFileName: nil)
        mockRepository.documentToReturn = document

        do {
            try await sut.execute(documentId: documentId)
            XCTFail("Expected fileURLNotFound error, but execution succeeded")
        } catch let error as AnalyzeDocumentError {
            XCTAssertEqual(error, .fileURLNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // Since AnalysisService is a singleton in the app and hard to mock directly without refactoring,
    // we can trigger failure using a file that doesn't exist so it fails extracting text.
    func testExecute_AnalysisFails_RevertsStatusToFailed() async {
        let documentId = UUID()
        let document = DocumentEntity(id: documentId, title: "Test Doc", savedFileName: "non_existent_file.pdf")
        mockRepository.documentToReturn = document

        do {
            try await sut.execute(documentId: documentId)
            XCTFail("Expected analysis to fail due to unreadable file")
        } catch {
            // First save should be processing, second should be failed
            XCTAssertEqual(mockRepository.savedDocuments.count, 2)
            XCTAssertEqual(mockRepository.savedDocuments[0].status, .processing)
            XCTAssertEqual(mockRepository.savedDocuments[1].status, .failed)
        }
    }
}
