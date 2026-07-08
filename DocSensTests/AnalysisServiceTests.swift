import XCTest
@testable import DocSens

final class AnalysisServiceTests: XCTestCase {

    func testComputeRiskScore_emptyFlags_returnsZero() async {
        let score = await AnalysisService.shared.computeRiskScore(flags: [])
        XCTAssertEqual(score, 0.0, accuracy: 0.001)
    }

    func testComputeRiskScore_singleLowRisk_returns0_05() async {
        let flag = RiskFlagEntity(keyword: "test", category: .liability, severity: .low, excerptContext: "")
        let score = await AnalysisService.shared.computeRiskScore(flags: [flag])
        XCTAssertEqual(score, 0.05, accuracy: 0.001)
    }

    func testComputeRiskScore_singleMediumRisk_returns0_15() async {
        let flag = RiskFlagEntity(keyword: "test", category: .liability, severity: .medium, excerptContext: "")
        let score = await AnalysisService.shared.computeRiskScore(flags: [flag])
        XCTAssertEqual(score, 0.15, accuracy: 0.001)
    }

    func testComputeRiskScore_singleHighRisk_returns0_3() async {
        let flag = RiskFlagEntity(keyword: "test", category: .liability, severity: .high, excerptContext: "")
        let score = await AnalysisService.shared.computeRiskScore(flags: [flag])
        XCTAssertEqual(score, 0.3, accuracy: 0.001)
    }

    func testComputeRiskScore_multipleRisks_sumsWeights() async {
        let flags = [
            RiskFlagEntity(keyword: "low", category: .liability, severity: .low, excerptContext: ""),
            RiskFlagEntity(keyword: "medium", category: .liability, severity: .medium, excerptContext: ""),
            RiskFlagEntity(keyword: "high", category: .liability, severity: .high, excerptContext: "")
        ]
        // 0.05 + 0.15 + 0.3 = 0.5
        let score = await AnalysisService.shared.computeRiskScore(flags: flags)
        XCTAssertEqual(score, 0.5, accuracy: 0.001)
    }

    func testComputeRiskScore_exceedsOne_capsAtOne() async {
        let flags = [
            RiskFlagEntity(keyword: "h1", category: .liability, severity: .high, excerptContext: ""),
            RiskFlagEntity(keyword: "h2", category: .liability, severity: .high, excerptContext: ""),
            RiskFlagEntity(keyword: "h3", category: .liability, severity: .high, excerptContext: ""),
            RiskFlagEntity(keyword: "h4", category: .liability, severity: .high, excerptContext: "")
        ]
        // 4 * 0.3 = 1.2 -> should cap at 1.0
        let score = await AnalysisService.shared.computeRiskScore(flags: flags)
        XCTAssertEqual(score, 1.0, accuracy: 0.001)
    }
}
