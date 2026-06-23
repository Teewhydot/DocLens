import Foundation

final class LocalFileImportService: FileImportService {
    static let documentsFolder: URL = {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("DocLens", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()
    
    func importFile(from sourceURL: URL, fileType: FileType) throws -> (url: URL, filename: String) {
        let ext = sourceURL.pathExtension.isEmpty
            ? (fileType == .pdf ? "pdf" : "jpg")
            : sourceURL.pathExtension
        let filename = UUID().uuidString + "." + ext
        let dest = Self.documentsFolder.appendingPathComponent(filename)
        try FileManager.default.copyItem(at: sourceURL, to: dest)
        return (dest, filename)
    }
    
    func deleteFile(filename: String) throws {
        let target = Self.documentsFolder.appendingPathComponent(filename)
        try FileManager.default.removeItem(at: target)
    }
}
