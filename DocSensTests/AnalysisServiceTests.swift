import XCTest
@testable import DocSens

final class AnalysisServiceTests: XCTestCase {

    func testAnalyze_UnreadableFile_ThrowsError() async {
        let service = AnalysisService.shared
        // Use a dummy URL that points to a non-existent file
        let url = URL(fileURLWithPath: "/path/to/nonexistent/file.png")

        do {
            _ = try await service.analyze(url: url, fileType: .image)
            XCTFail("Expected analyze to throw AnalysisError.unreadableFile, but it succeeded")
        } catch AnalysisError.unreadableFile {
            // Success: expected error was thrown
        } catch {
            XCTFail("Expected AnalysisError.unreadableFile, but got \(error)")
        }
    }
}
