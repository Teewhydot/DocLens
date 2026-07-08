import XCTest
@testable import DocSens

final class DocumentEntityTests: XCTestCase {

    func testRiskScoreOutOf100() {
        // Given
        var entity1 = DocumentEntity(title: "Test 1")
        var entity2 = DocumentEntity(title: "Test 2")
        var entity3 = DocumentEntity(title: "Test 3")
        var entity4 = DocumentEntity(title: "Test 4")

        // When
        entity1.riskScore = 0.0
        entity2.riskScore = 0.456
        entity3.riskScore = 0.899
        entity4.riskScore = 1.0

        // Then
        XCTAssertEqual(entity1.riskScoreOutOf100, 0, "0.0 should convert to 0")
        XCTAssertEqual(entity2.riskScoreOutOf100, 46, "0.456 should convert to 46 (rounded up)")
        XCTAssertEqual(entity3.riskScoreOutOf100, 90, "0.899 should convert to 90 (rounded up)")
        XCTAssertEqual(entity4.riskScoreOutOf100, 100, "1.0 should convert to 100")
    }

    func testResolvedFileURLWithSavedFileName() {
        // Given
        let savedFileName = "test_document.pdf"
        var entity = DocumentEntity(title: "Test Document")

        // When
        entity.savedFileName = savedFileName
        let resolvedURL = entity.resolvedFileURL

        // Then
        XCTAssertNotNil(resolvedURL, "resolvedFileURL should not be nil when savedFileName is set")

        let expectedBase = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let expectedURL = expectedBase.appendingPathComponent("DocSens", isDirectory: true).appendingPathComponent(savedFileName)

        XCTAssertEqual(resolvedURL, expectedURL, "resolvedFileURL should correctly append 'DocSens' and the file name to the document directory")
    }

    func testResolvedFileURLWithoutSavedFileName() {
        // Given
        let entity = DocumentEntity(title: "Unsaved Document", savedFileName: nil)

        // When
        let resolvedURL = entity.resolvedFileURL

        // Then
        XCTAssertNil(resolvedURL, "resolvedFileURL should be nil when savedFileName is nil")
    }
}
