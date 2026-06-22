import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var documents: [DocumentEntity]
    @Published var errorMessage: String?
    @Published var showImportOptions = false
    @Published var pendingDeletion: DocumentEntity?

    init(documents: [DocumentEntity] = []) {
        self.documents = documents
    }

    var isEmpty: Bool { documents.isEmpty }

    func delete(_ document: DocumentEntity) {
        documents.removeAll { $0.id == document.id }
    }

    func requestDelete(_ document: DocumentEntity) {
        pendingDeletion = document
    }

    func confirmDelete() {
        if let doc = pendingDeletion {
            delete(doc)
        }
        pendingDeletion = nil
    }
}

extension HomeViewModel {
    /// Mock VM for previews — populated with sample documents.
    static var mock: HomeViewModel { HomeViewModel(documents: SampleData.documents) }
    /// Mock empty VM to preview the empty state.
    static var mockEmpty: HomeViewModel { HomeViewModel(documents: []) }
}
