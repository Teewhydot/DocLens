import Foundation

/// Static sample data — rich enough to exercise all UI states.
/// UUIDs are generated at app-launch and stored here so we can cross-reference
/// documents, entity mentions, and risk flags during a session.
enum SampleData {
    static func date(_ daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
    }

    // Stable per-launch session identifiers
    private static let ndaId   = UUID()
    private static let empId   = UUID()
    private static let sowId   = UUID()
    private static let leaseId = UUID()

    // MARK: - Documents

    static let documents: [DocumentEntity] = [
        DocumentEntity(id: ndaId,   title: "Mutual NDA — Acme & Northwind",  importedAt: date(2),  fileType: .pdf,   extractedText: ndaText,   detectedLanguage: "English", riskScore: 0.18, status: .complete),
        DocumentEntity(id: empId,   title: "Employment Agreement 2025",       importedAt: date(9),  fileType: .pdf,   extractedText: empText,   detectedLanguage: "English", riskScore: 0.47, status: .complete),
        DocumentEntity(id: sowId,   title: "Freelance SOW — Photography",     importedAt: date(15), fileType: .image, extractedText: sowText,   detectedLanguage: "English", riskScore: 0.72, status: .complete),
        DocumentEntity(id: leaseId, title: "Office Lease Renewal",            importedAt: date(21), fileType: .pdf,   extractedText: leaseText, detectedLanguage: "English", riskScore: 0,    status: .processing),
    ]

    // MARK: - Entity Mentions (keyed by the same session IDs)

    static let entityMentions: [UUID: [EntityMentionEntity]] = {
        [
            ndaId: [
                EntityMentionEntity(type: .organization, value: "Acme Corporation",  confidence: 0.97),
                EntityMentionEntity(type: .organization, value: "Northwind Traders", confidence: 0.95),
                EntityMentionEntity(type: .person,       value: "Jane Smith",        confidence: 0.91),
                EntityMentionEntity(type: .person,       value: "Robert Chen",       confidence: 0.88),
                EntityMentionEntity(type: .date,         value: "January 15, 2025",  confidence: 0.99),
                EntityMentionEntity(type: .date,         value: "December 31, 2027", confidence: 0.99),
                EntityMentionEntity(type: .place,        value: "New York, NY",      confidence: 0.85),
            ],
            empId: [
                EntityMentionEntity(type: .organization, value: "Horizon Tech Inc.",  confidence: 0.96),
                EntityMentionEntity(type: .person,       value: "Michael Torres",     confidence: 0.93),
                EntityMentionEntity(type: .money,        value: "$145,000",           confidence: 0.99),
                EntityMentionEntity(type: .money,        value: "$20,000",            confidence: 0.98),
                EntityMentionEntity(type: .date,         value: "March 1, 2025",      confidence: 0.99),
                EntityMentionEntity(type: .place,        value: "San Francisco, CA",  confidence: 0.87),
                EntityMentionEntity(type: .date,         value: "February 15, 2025",  confidence: 0.95),
            ],
            sowId: [
                EntityMentionEntity(type: .person,       value: "Lisa Nakamura",     confidence: 0.92),
                EntityMentionEntity(type: .organization, value: "Spark Studios LLC", confidence: 0.94),
                EntityMentionEntity(type: .money,        value: "$8,500",            confidence: 0.99),
                EntityMentionEntity(type: .money,        value: "$2,500",            confidence: 0.98),
                EntityMentionEntity(type: .date,         value: "April 10, 2025",    confidence: 0.99),
                EntityMentionEntity(type: .phoneNumber,  value: "(415) 555-0192",    confidence: 0.97),
                EntityMentionEntity(type: .place,        value: "Los Angeles, CA",   confidence: 0.82),
            ],
        ]
    }()

    // MARK: - Risk Flags

    static let riskFlags: [UUID: [RiskFlagEntity]] = {
        [
            ndaId: [
                RiskFlagEntity(keyword: "dispute resolution",    category: .arbitration, severity: .low,    excerptContext: "…Any dispute arising under this Agreement shall be subject to dispute resolution through mediation before any litigation may be commenced…"),
                RiskFlagEntity(keyword: "consequential damages", category: .liability,   severity: .medium, excerptContext: "…In no event shall either party be liable for any indirect, incidental, or consequential damages arising out of the use or inability to use…"),
            ],
            empId: [
                RiskFlagEntity(keyword: "non-compete",     category: .nonCompete,   severity: .high,   excerptContext: "…Employee agrees not to engage in any non-compete activity within a 50-mile radius for a period of 24 months following termination…"),
                RiskFlagEntity(keyword: "work for hire",   category: .ipAssignment, severity: .high,   excerptContext: "…Employee hereby assigns all intellectual property created during employment to Horizon Tech Inc., including any inventions or software…"),
                RiskFlagEntity(keyword: "arbitration",     category: .arbitration,  severity: .high,   excerptContext: "…The parties agree to submit any disputes to binding arbitration under AAA rules, and each party waives the right to jury trial…"),
                RiskFlagEntity(keyword: "auto-renew",      category: .autoRenewal,  severity: .medium, excerptContext: "…This Agreement shall automatically renew for successive one-year terms unless either party provides 90-day written notice…"),
                RiskFlagEntity(keyword: "penalty",         category: .penalties,    severity: .medium, excerptContext: "…A penalty equal to three months salary shall apply if Employee resigns without providing the full 60-day notice period…"),
            ],
            sowId: [
                RiskFlagEntity(keyword: "work for hire",    category: .ipAssignment, severity: .high,   excerptContext: "…All deliverables produced under this Statement of Work shall be considered work for hire and all rights vest exclusively in Spark Studios LLC…"),
                RiskFlagEntity(keyword: "indemnify",        category: .liability,    severity: .high,   excerptContext: "…Contractor shall indemnify, defend, and hold harmless Spark Studios from any third-party claims arising from Contractors services…"),
                RiskFlagEntity(keyword: "late fee",         category: .penalties,    severity: .low,    excerptContext: "…Invoices unpaid after 30 days will incur a late fee of 1.5 percent per month on the outstanding balance…"),
                RiskFlagEntity(keyword: "non-solicitation", category: .nonCompete,   severity: .medium, excerptContext: "…Contractor agrees not to directly solicit any clients or employees of Spark Studios for a period of 12 months after project completion…"),
            ],
        ]
    }()

    // MARK: - Extracted text blurbs

    static let ndaText = """
    MUTUAL NON-DISCLOSURE AGREEMENT
    This Agreement is entered into as of January 15, 2025, by and between Acme Corporation and Northwind Traders.
    The parties agree to keep all Confidential Information strictly confidential. Any dispute resolution arising under this Agreement shall be through mediation. In no event shall either party be liable for any indirect, incidental, or consequential damages.
    Signed: Jane Smith (Acme) and Robert Chen (Northwind). Jurisdiction: New York, NY. Term expires December 31, 2027.
    """

    static let empText = """
    EMPLOYMENT AGREEMENT
    This Agreement is entered into as of March 1, 2025 between Horizon Tech Inc. and Michael Torres.
    Compensation: $145,000 per year plus a signing bonus of $20,000. Start Date: February 15, 2025. Location: San Francisco, CA.
    Employee agrees not to engage in any non-compete activity within a 50-mile radius for 24 months. Employee hereby assigns all intellectual property to Horizon Tech Inc. Disputes subject to arbitration. This Agreement shall auto-renew unless 90-day notice given. A penalty equal to three months salary applies for early resignation.
    """

    static let sowText = """
    STATEMENT OF WORK — PHOTOGRAPHY SERVICES
    Client: Spark Studios LLC. Contractor: Lisa Nakamura. Date: April 10, 2025. Location: Los Angeles, CA.
    Total fee: $8,500 with a $2,500 deposit due on signing. Contact: (415) 555-0192.
    All deliverables shall be considered work for hire. Contractor shall indemnify and hold harmless Spark Studios from third-party claims. Invoices unpaid after 30 days incur a late fee of 1.5 percent per month. Contractor agrees to a non-solicitation clause for 12 months after project completion.
    """

    static let leaseText = "Analysis pending. This document is currently being processed on-device."
}
