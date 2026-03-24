import Foundation
import FirebaseFirestore

@Observable
class DepositViewModel {
    var deposits: [Deposit] = []
    var isLoading = true
    var errorMessage: String?

    private var listener: ListenerRegistration?

    var totalDeposits: Double { deposits.reduce(0) { $0 + $1.amount } }

    func subscribe(uid: String, year: Int = CURRENT_YEAR) {
        listener?.remove()
        isLoading = true
        listener = DepositService.subscribe(uid: uid, year: year) { [weak self] deposits in
            self?.deposits = deposits
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
        listener = nil
    }

    func add(uid: String, deposit: Deposit) async -> String? {
        do {
            return try await DepositService.add(uid: uid, deposit: deposit)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func delete(uid: String, depositId: String, walletId: String, amount: Double) async {
        do {
            try await DepositService.delete(uid: uid, depositId: depositId, walletId: walletId, amount: amount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
