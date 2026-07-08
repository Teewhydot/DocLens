import Foundation

final class LocalFileImportService: FileImportService {
    static let documentsFolder: URL = {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("DocSens", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()
    
    func importFile(from sourceURL: URL, fileType: FileType) throws -> (url: URL, filename: String) {
        var safeExt = sourceURL.pathExtension
        if safeExt.contains("/") || safeExt.contains("\\") || safeExt.contains("..") || safeExt.contains("\0") {
            safeExt = ""
        }

        let ext = safeExt.isEmpty
            ? (fileType == .pdf ? "pdf" : "jpg")
            : safeExt

        let filename = UUID().uuidString + "." + ext
        let dest = Self.documentsFolder.appendingPathComponent(filename)
        try FileManager.default.copyItem(at: sourceURL, to: dest)
        return (dest, filename)
    }
    
    func deleteFile(filename: String) throws {
        guard !filename.contains("/") && !filename.contains("\\") && !filename.contains("..") && !filename.contains("\0") else {
            throw NSError(domain: "LocalFileImportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid filename"])
        }

        let target = Self.documentsFolder.appendingPathComponent(filename)
        try FileManager.default.removeItem(at: target)
    }
}
