import Foundation
import FirebaseFirestore

@Observable
class WalletViewModel {
    var wallets: [Wallet] = []
    var isLoading = true
    var errorMessage: String?

    private var listener: ListenerRegistration?

    var bankWallets: [Wallet] { wallets.filter { $0.type == .bank } }
    var cashWallets: [Wallet] { wallets.filter { $0.type == .cash } }
    var totalBalance: Double { wallets.reduce(0) { $0 + $1.balance } }

    func subscribe(uid: String, year: Int = CURRENT_YEAR) {
        listener?.remove()
        isLoading = true
        listener = WalletService.subscribe(uid: uid, year: year) { [weak self] wallets in
            self?.wallets = wallets
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
        listener = nil
    }

    func add(uid: String, wallet: Wallet) async -> String? {
        do {
            return try await WalletService.add(uid: uid, wallet: wallet)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func update(uid: String, walletId: String, data: [String: Any]) async {
        do {
            try await WalletService.update(uid: uid, walletId: walletId, data: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(uid: String, walletId: String) async {
        do {
            try await WalletService.delete(uid: uid, walletId: walletId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func withdraw(uid: String, bankWalletId: String, cashWalletId: String, amount: Double, fee: Double, bankName: String) async {
        do {
            try await WalletService.withdraw(uid: uid, bankWalletId: bankWalletId, cashWalletId: cashWalletId, amount: amount, fee: fee, bankName: bankName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
