import Foundation

/// Static sample data used to bring the UI to life in previews and the
/// initial build before the Core Data + analysis pipeline is wired in.
enum SampleData {
    static func date(_ daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
    }

    static let documents: [DocumentEntity] = [
        DocumentEntity(
            title: "Mutual NDA — Acme & Northwind",
            importedAt: date(2),
            fileType: .pdf,
            detectedLanguage: "English",
            riskScore: 0.18,
            status: .complete
        ),
        DocumentEntity(
            title: "Employment Agreement 2025",
            importedAt: date(9),
            fileType: .pdf,
            detectedLanguage: "English",
            riskScore: 0.47,
            status: .complete
        ),
        DocumentEntity(
            title: "Freelance SOW — Photography",
            importedAt: date(15),
            fileType: .image,
            detectedLanguage: "English",
            riskScore: 0.72,
            status: .complete
        ),
        DocumentEntity(
            title: "Office Lease Renewal",
            importedAt: date(21),
            fileType: .pdf,
            detectedLanguage: "English",
            riskScore: 0,
            status: .processing
        )
    ]
}
