import Foundation
import FirebaseFirestore
import SwiftUI

@Observable
class ReceivableViewModel {
    var receivables: [Receivable] = []
    var isLoading = true
    var errorMessage: String?

    private var listener: ListenerRegistration?

    var totalReceivables: Double { receivables.reduce(0) { $0 + max($1.remaining, 0) } }

    func subscribe(uid: String, year: Int = CURRENT_YEAR) {
        listener?.remove()
        isLoading = true
        listener = ReceivableService.subscribe(uid: uid, year: year) { [weak self] items in
            withAnimation {
                self?.receivables = items
                self?.isLoading = false
            }
        }
    }

    func unsubscribe() {
        listener?.remove()
        listener = nil
    }

    func add(uid: String, receivable: Receivable) async -> String? {
        do {
            return try await ReceivableService.add(uid: uid, receivable: receivable)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func update(uid: String, receivableId: String, data: [String: Any]) async {
        do {
            try await ReceivableService.update(uid: uid, receivableId: receivableId, data: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(uid: String, receivableId: String, sourceId: String = "", amount: Double = 0) async {
        do {
            try await ReceivableService.delete(uid: uid, receivableId: receivableId, sourceId: sourceId, amount: amount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
