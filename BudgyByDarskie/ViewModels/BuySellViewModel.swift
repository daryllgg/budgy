import Foundation
import FirebaseFirestore

@Observable
class BuySellViewModel {
    var transactions: [BuySellTransaction] = []
    var isLoading = true
    var errorMessage: String?

    private var listener: ListenerRegistration?

    var totalProfit: Double { transactions.reduce(0) { $0 + ($1.profit ?? 0) } }
    var soldCount: Int { transactions.filter { $0.status == .sold }.count }
    var pendingCount: Int { transactions.filter { $0.status == .pending }.count }
    var availableCount: Int { transactions.filter { $0.status == .available }.count }

    var profitByType: [ItemType: Double] {
        Dictionary(grouping: transactions.filter { $0.status == .sold }, by: \.itemType)
            .mapValues { $0.reduce(0) { $0 + ($1.profit ?? 0) } }
    }

    func subscribe(uid: String, year: Int = CURRENT_YEAR) {
        listener?.remove()
        isLoading = true
        listener = BuySellService.subscribe(uid: uid, year: year) { [weak self] txs in
            self?.transactions = txs
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
        listener = nil
    }

    func add(uid: String, tx: BuySellTransaction) async -> String? {
        do {
            return try await BuySellService.add(uid: uid, tx: tx)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func update(uid: String, txId: String, oldFundingSources: [FundingSource], tx: BuySellTransaction) async {
        do {
            try await BuySellService.update(uid: uid, txId: txId, oldFundingSources: oldFundingSources, tx: tx)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(uid: String, txId: String, fundingSources: [FundingSource]) async {
        do {
            try await BuySellService.delete(uid: uid, txId: txId, fundingSources: fundingSources)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
