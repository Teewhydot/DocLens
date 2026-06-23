import Foundation

// MARK: - Domain enums

enum FileType: String, Codable {
    case pdf
    case image
}

enum AnalysisStatus: String, Codable {
    case pending
    case processing
    case complete
    case failed

    var displayLabel: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing…"
        case .complete: return "Complete"
        case .failed: return "Failed"
        }
    }
}

enum EntityType: String, Codable, CaseIterable {
    case person, organization, date, money, place, phoneNumber

    var displayName: String {
        switch self {
        case .person: return "Person"
        case .organization: return "Organization"
        case .date: return "Date"
        case .money: return "Money"
        case .place: return "Place"
        case .phoneNumber: return "Phone"
        }
    }

    var symbol: String {
        switch self {
        case .person: return "person.fill"
        case .organization: return "building.2.fill"
        case .date: return "calendar"
        case .money: return "dollarsign.circle.fill"
        case .place: return "mappin.circle.fill"
        case .phoneNumber: return "phone.fill"
        }
    }
}

enum RiskCategory: String, Codable, CaseIterable {
    case liability, ipAssignment, nonCompete, penalties, autoRenewal, arbitration

    var displayName: String {
        switch self {
        case .liability: return "Liability"
        case .ipAssignment: return "IP"
        case .nonCompete: return "Non-Compete"
        case .penalties: return "Penalties"
        case .autoRenewal: return "Auto-Renewal"
        case .arbitration: return "Arbitration"
        }
    }
}

enum RiskSeverity: String, Codable {
    case low, medium, high
}

// MARK: - Domain models

struct DocumentEntity: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var importedAt: Date
    var fileType: FileType
    /// Relative filename inside the app's Documents/DocLens/ folder (or nil for unsaved docs)
    var savedFileName: String?
    var extractedText: String
    var detectedLanguage: String
    var riskScore: Double          // 0.0 – 1.0
    var status: AnalysisStatus

    init(
        id: UUID = UUID(),
        title: String,
        importedAt: Date = .now,
        fileType: FileType = .pdf,
        savedFileName: String? = nil,
        extractedText: String = "",
        detectedLanguage: String = "—",
        riskScore: Double = 0,
        status: AnalysisStatus = .pending
    ) {
        self.id = id
        self.title = title
        self.importedAt = importedAt
        self.fileType = fileType
        self.savedFileName = savedFileName
        self.extractedText = extractedText
        self.detectedLanguage = detectedLanguage
        self.riskScore = riskScore
        self.status = status
    }

    var riskScoreOutOf100: Int { Int((riskScore * 100).rounded()) }

    /// Resolves the absolute URL for the saved file (if any).
    var resolvedFileURL: URL? {
        guard let name = savedFileName else { return nil }
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("DocLens", isDirectory: true).appendingPathComponent(name)
    }
}

struct EntityMentionEntity: Identifiable, Hashable, Codable {
    let id: UUID
    var type: EntityType
    var value: String
    var confidence: Double

    init(id: UUID = UUID(), type: EntityType, value: String, confidence: Double) {
        self.id = id
        self.type = type
        self.value = value
        self.confidence = confidence
    }
}

struct RiskFlagEntity: Identifiable, Hashable, Codable {
    let id: UUID
    var keyword: String
    var category: RiskCategory
    var severity: RiskSeverity
    var excerptContext: String

    init(id: UUID = UUID(), keyword: String, category: RiskCategory, severity: RiskSeverity, excerptContext: String) {
        self.id = id
        self.keyword = keyword
        self.category = category
        self.severity = severity
        self.excerptContext = excerptContext
    }
}
