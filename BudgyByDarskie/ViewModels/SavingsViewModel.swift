import Foundation
import FirebaseFirestore

@Observable
class SavingsViewModel {
    var items: [SavingsBreakdown] = []
    var isLoading = true
    var errorMessage: String?

    private var listener: ListenerRegistration?

    var totalSavings: Double { items.reduce(0) { $0 + $1.amount } }

    func subscribe(uid: String, year: Int = CURRENT_YEAR) {
        listener?.remove()
        isLoading = true
        listener = SavingsService.subscribe(uid: uid, year: year) { [weak self] items in
            self?.items = items
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
        listener = nil
    }

    func add(uid: String, item: SavingsBreakdown) async {
        do {
            try await SavingsService.add(uid: uid, item: item)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(uid: String, itemId: String, data: [String: Any]) async {
        do {
            try await SavingsService.update(uid: uid, itemId: itemId, data: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(uid: String, itemId: String) async {
        do {
            try await SavingsService.delete(uid: uid, itemId: itemId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
