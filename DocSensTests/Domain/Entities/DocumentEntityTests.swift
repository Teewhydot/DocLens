import XCTest
@testable import DocSens

final class DocumentEntityTests: XCTestCase {

    func testRiskScoreOutOf100() {
        // Given
        var entity = DocumentEntity(title: "Test Doc")

        // When/Then for various risk scores
        entity.riskScore = 0.0
        XCTAssertEqual(entity.riskScoreOutOf100, 0, "0.0 should convert to 0")

        entity.riskScore = 0.5
        XCTAssertEqual(entity.riskScoreOutOf100, 50, "0.5 should convert to 50")

        entity.riskScore = 1.0
        XCTAssertEqual(entity.riskScoreOutOf100, 100, "1.0 should convert to 100")

        entity.riskScore = 0.123
        XCTAssertEqual(entity.riskScoreOutOf100, 12, "0.123 should convert to 12")

        entity.riskScore = 0.125
        XCTAssertEqual(entity.riskScoreOutOf100, 13, "0.125 should convert to 13 (rounded up)")

        entity.riskScore = 0.999
        XCTAssertEqual(entity.riskScoreOutOf100, 100, "0.999 should convert to 100")
    }

    func testResolvedFileURLWithSavedFileName() {
        // Given
        let fileName = "test-doc.pdf"
        var entity = DocumentEntity(title: "Test Doc")
        entity.savedFileName = fileName

        // When
        let url = entity.resolvedFileURL

        // Then
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.path.contains("DocSens/test-doc.pdf") ?? false, "URL should contain the DocSens directory and filename")
    }

    func testResolvedFileURLWithoutSavedFileName() {
        // Given
        let entity = DocumentEntity(title: "Test Doc", savedFileName: nil)

        // When
        let url = entity.resolvedFileURL

        // Then
        XCTAssertNil(url, "URL should be nil when savedFileName is nil")
    }
}
