import Foundation

protocol FileImportService: Sendable {
    func importFile(from sourceURL: URL, fileType: FileType) throws -> (url: URL, filename: String)
    func deleteFile(filename: String) throws
}
