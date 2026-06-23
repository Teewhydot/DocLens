import Foundation
import SwiftUI
import Combine
import CoreData

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var documents: [DocumentEntity] = []
    
    private let repository: DocumentRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: DocumentRepository = CoreDataDocumentRepository()) {
        self.repository = repository
        
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.fetchDocuments()
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchDocuments() async {
        if let docs = try? await repository.getAllDocuments() {
            self.documents = docs
        }
    }
}
