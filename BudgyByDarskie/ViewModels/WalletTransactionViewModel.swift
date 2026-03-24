import Foundation
import FirebaseFirestore

@Observable
class WalletTransactionViewModel {
    var transactions: [WalletTransaction] = []
    var isLoading = true

    private var listeners: [ListenerRegistration] = []

    var totalIn: Double {
        transactions.filter { $0.type.isInflow }.reduce(0) { $0 + $1.amount }
    }

    var totalOut: Double {
        transactions.filter { !$0.type.isInflow }.reduce(0) { $0 + $1.amount }
    }

    /// Group transactions by month-year for section headers
    var groupedByMonth: [(key: String, transactions: [WalletTransaction])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: transactions) { formatter.string(from: $0.date) }

        return grouped
            .sorted { lhs, rhs in
                guard let lDate = lhs.value.first?.date, let rDate = rhs.value.first?.date else { return false }
                return lDate > rDate
            }
            .map { (key: $0.key, transactions: $0.value) }
    }

    func subscribe(uid: String, walletId: String, year: Int = CURRENT_YEAR) {
        unsubscribe()
        isLoading = true
        listeners = WalletTransactionService.subscribe(uid: uid, walletId: walletId, year: year) { [weak self] txs in
            self?.transactions = txs
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listeners.forEach { $0.remove() }
        listeners = []
    }
}
