import XCTest
@testable import DocSens

final class AnalysisServiceTests: XCTestCase {

    func testExtractExcerpt_KeywordNotFound() async {
        let text = "This is a sample document without the target word."
        let excerpt = await AnalysisService.shared.extractExcerpt(for: "missing", in: text)
        XCTAssertEqual(excerpt, "", "Excerpt should be empty if keyword is not found.")
    }

    func testExtractExcerpt_KeywordNearStart() async {
        let text = "liability is a huge concern for many companies."
        let excerpt = await AnalysisService.shared.extractExcerpt(for: "liability", in: text)
        XCTAssertEqual(excerpt, "…liability is a huge concern for many companies.…", "Excerpt should correctly handle bounds at the start.")
    }

    func testExtractExcerpt_KeywordNearEnd() async {
        let text = "Many companies have a huge concern about liability"
        let excerpt = await AnalysisService.shared.extractExcerpt(for: "liability", in: text)
        XCTAssertEqual(excerpt, "…Many companies have a huge concern about liability…", "Excerpt should correctly handle bounds at the end.")
    }

    func testExtractExcerpt_KeywordExactlyMatching() async {
        let text = "liability"
        let excerpt = await AnalysisService.shared.extractExcerpt(for: "liability", in: text)
        XCTAssertEqual(excerpt, "…liability…", "Excerpt should correctly handle text exactly matching keyword.")
    }

    func testExtractExcerpt_EmptyText() async {
        let text = ""
        let excerpt = await AnalysisService.shared.extractExcerpt(for: "liability", in: text)
        XCTAssertEqual(excerpt, "", "Excerpt should be empty for empty text.")
    }

    func testExtractExcerpt_WhitespaceTrimming() async {
        let text = "   \n  This contract includes a penalty clause for late deliveries.   \n   "
        let excerpt = await AnalysisService.shared.extractExcerpt(for: "penalty", in: text)
        XCTAssertEqual(excerpt, "…This contract includes a penalty clause for late deliveries.…", "Excerpt should trim whitespace and newlines.")
    }

    func testExtractExcerpt_LongText() async {
        let prefix = String(repeating: "A", count: 250)
        let suffix = String(repeating: "Z", count: 250)
        let text = prefix + "penalty" + suffix
        let excerpt = await AnalysisService.shared.extractExcerpt(for: "penalty", in: text)

        // We expect up to 200 characters before and after the keyword.
        let expectedPrefix = String(repeating: "A", count: 200)
        let expectedSuffix = String(repeating: "Z", count: 200)
        let expected = "…" + expectedPrefix + "penalty" + expectedSuffix + "…"

        XCTAssertEqual(excerpt, expected, "Excerpt should limit bounds to 200 characters before and after.")
    }

    func testExtractExcerpt_CaseInsensitive() async {
        let text = "The PENALTY is huge."
        let excerpt = await AnalysisService.shared.extractExcerpt(for: "penalty", in: text)
        XCTAssertEqual(excerpt, "…The PENALTY is huge.…", "Excerpt should match case-insensitively.")
    }
}
