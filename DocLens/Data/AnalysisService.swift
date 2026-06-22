import Foundation
import Vision
import NaturalLanguage
import UIKit

/// On-device analysis pipeline: OCR → entity extraction → risk scoring.
/// All processing happens locally — no data leaves the device.
actor AnalysisService {
    static let shared = AnalysisService()
    private init() {}

    // MARK: - Public entry point

    struct AnalysisResult {
        let extractedText: String
        let detectedLanguage: String
        let entities: [EntityMentionEntity]
        let flags: [RiskFlagEntity]
        let riskScore: Double
    }

    /// Analyzes a PDF/image at `url`. Throws on read failure.
    func analyze(url: URL, fileType: FileType) async throws -> AnalysisResult {
        let text = try await extractText(url: url, fileType: fileType)
        let lang = detectLanguage(text)
        let entities = extractEntities(from: text)
        let flags = scanRiskFlags(in: text)
        let score = computeRiskScore(flags: flags)
        return AnalysisResult(
            extractedText: text,
            detectedLanguage: lang,
            entities: entities,
            flags: flags,
            riskScore: score
        )
    }

    // MARK: - OCR / text extraction

    private func extractText(url: URL, fileType: FileType) async throws -> String {
        switch fileType {
        case .pdf:
            return try await extractTextFromPDF(url: url)
        case .image:
            guard let img = UIImage(contentsOfFile: url.path),
                  let cgImg = img.cgImage else {
                throw AnalysisError.unreadableFile
            }
            return try await recognizeText(in: cgImg)
        }
    }

    private func extractTextFromPDF(url: URL) async throws -> String {
        guard let dataProvider = CGDataProvider(url: url as CFURL),
              let pdf = CGPDFDocument(dataProvider) else {
            throw AnalysisError.unreadableFile
        }
        var pages: [String] = []
        let pageCount = min(pdf.numberOfPages, 10) // cap at 10 pages for performance
        for i in 1...pageCount {
            guard let page = pdf.page(at: i) else { continue }
            let pageRect = page.getBoxRect(.mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let img = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(pageRect)
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                ctx.cgContext.drawPDFPage(page)
            }
            if let cg = img.cgImage {
                if let pageText = try? await recognizeText(in: cg) {
                    pages.append(pageText)
                }
            }
        }
        return pages.joined(separator: "\n\n")
    }

    private func recognizeText(in cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, err in
                if let err { continuation.resume(throwing: err); return }
                let obs = req.results as? [VNRecognizedTextObservation] ?? []
                let lines = obs.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do { try handler.perform([request]) } catch { continuation.resume(throwing: error) }
        }
    }

    // MARK: - Language detection

    private func detectLanguage(_ text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(String(text.prefix(500)))
        guard let lang = recognizer.dominantLanguage else { return "Unknown" }
        let locale = Locale(identifier: "en")
        return locale.localizedString(forLanguageCode: lang.rawValue) ?? lang.rawValue
    }

    // MARK: - Entity extraction

    private func extractEntities(from text: String) -> [EntityMentionEntity] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var seen = Set<String>()
        var results: [EntityMentionEntity] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        let range = text.startIndex..<text.endIndex

        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            guard let tag else { return true }
            let value = String(text[tokenRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard value.count > 1, !seen.contains(value) else { return true }
            seen.insert(value)
            let entityType: EntityType? = switch tag {
            case .personalName: .person
            case .organizationName: .organization
            case .placeName: .place
            default: nil
            }
            if let type = entityType {
                results.append(EntityMentionEntity(type: type, value: value, confidence: 0.85))
            }
            return true
        }

        // Money & phone patterns via regex
        results += extractMoneyMentions(from: text, seen: &seen)
        results += extractPhoneMentions(from: text, seen: &seen)
        results += extractDateMentions(from: text, seen: &seen)
        return Array(results.prefix(40))
    }

    private func extractMoneyMentions(from text: String, seen: inout Set<String>) -> [EntityMentionEntity] {
        let pattern = #"\$[\d,]+(?:\.\d{2})?|\b\d[\d,]*(?:\.\d{2})?\s*(?:USD|EUR|GBP)\b"#
        return regexMatches(pattern: pattern, in: text, type: .money, seen: &seen)
    }

    private func extractPhoneMentions(from text: String, seen: inout Set<String>) -> [EntityMentionEntity] {
        let pattern = #"(?:\+1\s?)?\(?\d{3}\)?[\s\-]\d{3}[\s\-]\d{4}"#
        return regexMatches(pattern: pattern, in: text, type: .phoneNumber, seen: &seen)
    }

    private func extractDateMentions(from text: String, seen: inout Set<String>) -> [EntityMentionEntity] {
        let pattern = #"\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},?\s+\d{4}\b|\b\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}\b"#
        return regexMatches(pattern: pattern, in: text, type: .date, seen: &seen)
    }

    private func regexMatches(pattern: String, in text: String, type: EntityType, seen: inout Set<String>) -> [EntityMentionEntity] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { m in
            let val = ns.substring(with: m.range).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !seen.contains(val) else { return nil }
            seen.insert(val)
            return EntityMentionEntity(type: type, value: val, confidence: 0.9)
        }
    }

    // MARK: - Risk scanning

    private static let riskKeywords: [(keyword: String, category: RiskCategory, severity: RiskSeverity)] = [
        // Liability
        ("indemnif", .liability, .high),
        ("hold harmless", .liability, .high),
        ("unlimited liability", .liability, .high),
        ("consequential damages", .liability, .medium),
        ("liquidated damages", .penalties, .medium),
        // IP Assignment
        ("assigns all intellectual property", .ipAssignment, .high),
        ("work for hire", .ipAssignment, .high),
        ("moral rights waived", .ipAssignment, .medium),
        ("perpetual license", .ipAssignment, .medium),
        // Non-compete
        ("non-compete", .nonCompete, .high),
        ("non compete", .nonCompete, .high),
        ("compete directly", .nonCompete, .medium),
        ("non-solicitation", .nonCompete, .medium),
        // Penalties
        ("penalty", .penalties, .medium),
        ("late fee", .penalties, .low),
        ("interest at the rate", .penalties, .low),
        // Auto-renewal
        ("automatically renew", .autoRenewal, .medium),
        ("auto-renew", .autoRenewal, .medium),
        ("evergreen clause", .autoRenewal, .high),
        ("unless terminated in writing", .autoRenewal, .low),
        // Arbitration
        ("binding arbitration", .arbitration, .high),
        ("waives right to jury", .arbitration, .high),
        ("class action waiver", .arbitration, .high),
        ("dispute resolution", .arbitration, .low),
    ]

    private func scanRiskFlags(in text: String) -> [RiskFlagEntity] {
        let lower = text.lowercased()
        var flags: [RiskFlagEntity] = []
        for rule in Self.riskKeywords {
            guard lower.contains(rule.keyword) else { continue }
            let excerpt = extractExcerpt(for: rule.keyword, in: text)
            flags.append(RiskFlagEntity(keyword: rule.keyword, category: rule.category, severity: rule.severity, excerptContext: excerpt))
        }
        return flags
    }

    private func extractExcerpt(for keyword: String, in text: String) -> String {
        let lower = text.lowercased()
        guard let range = lower.range(of: keyword) else { return "" }
        let start = text.index(range.lowerBound, offsetBy: -120, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: 160, limitedBy: text.endIndex) ?? text.endIndex
        return "…" + String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    // MARK: - Risk score

    private func computeRiskScore(flags: [RiskFlagEntity]) -> Double {
        guard !flags.isEmpty else { return 0 }
        let weights: [RiskSeverity: Double] = [.low: 0.05, .medium: 0.15, .high: 0.3]
        let raw = flags.reduce(0.0) { $0 + (weights[$1.severity] ?? 0) }
        return min(raw, 1.0)
    }
}

// MARK: - Errors

enum AnalysisError: LocalizedError {
    case unreadableFile
    var errorDescription: String? { "Could not read the file. Please make sure it is not corrupted." }
}
