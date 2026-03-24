import Foundation
import FirebaseFirestore

struct WalletService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("wallets")
    }

    static func subscribe(uid: String, year: Int, onChange: @escaping ([Wallet]) -> Void) -> ListenerRegistration {
        col(uid)
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let wallets = docs.compactMap { try? $0.data(as: Wallet.self) }
                    .sorted { ($0.type.rawValue, $0.order) < ($1.type.rawValue, $1.order) }
                onChange(wallets)
            }
    }

    @discardableResult
    static func add(uid: String, wallet: Wallet) async throws -> String {
        let data: [String: Any] = [
            "name": wallet.name,
            "type": wallet.type.rawValue,
            "bankName": wallet.bankName,
            "balance": wallet.balance,
            "notes": wallet.notes,
            "year": wallet.year,
            "order": Date().timeIntervalSince1970 * 1000,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        let docId = col(uid).document().documentID
        col(uid).document(docId).setData(data, completion: nil)
        ActivityLogService.log(uid: uid, type: .wallet, action: .add, description: "Added wallet: \(wallet.name)", amount: wallet.balance)
        return docId
    }

    static func update(uid: String, walletId: String, data: [String: Any]) async throws {
        var data = data
        data["updatedAt"] = FieldValue.serverTimestamp()
        col(uid).document(walletId).updateData(data, completion: nil)
    }

    static func delete(uid: String, walletId: String) async throws {
        col(uid).document(walletId).delete(completion: nil)
        ActivityLogService.log(uid: uid, type: .wallet, action: .delete, description: "Deleted wallet")
    }

    static func withdraw(uid: String, bankWalletId: String, cashWalletId: String, amount: Double, fee: Double, bankName: String) async throws {
        let bankRef = col(uid).document(bankWalletId)
        let cashRef = col(uid).document(cashWalletId)
        let expenseCol = db.collection("users").document(uid).collection("expenses")
        let withdrawalCol = db.collection("users").document(uid).collection("withdrawals")

        // Get cash wallet name
        let cashDoc = try? await cashRef.getDocument()
        let cashWalletName = cashDoc?.data()?["name"] as? String ?? "Cash"

        let batch = db.batch()

        // Deduct amount + fee from bank
        batch.updateData([
            "balance": FieldValue.increment(-(amount + fee)),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: bankRef)

        // Add amount to cash
        batch.updateData([
            "balance": FieldValue.increment(amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: cashRef)

        // Add fee as expense
        if fee > 0 {
            let expenseRef = expenseCol.document()
            batch.setData([
                "description": "Transaction Fee",
                "amount": fee,
                "date": Timestamp(date: Date()),
                "category": ExpenseCategory.other.rawValue,
                "sourceId": bankWalletId,
                "sourceName": bankName,
                "notes": "ATM/Bank withdrawal fee",
                "year": CURRENT_YEAR,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
            ], forDocument: expenseRef)
        }

        // Log withdrawal record
        let withdrawalRef = withdrawalCol.document()
        batch.setData([
            "amount": amount,
            "fee": fee,
            "bankWalletId": bankWalletId,
            "bankWalletName": bankName,
            "cashWalletId": cashWalletId,
            "cashWalletName": cashWalletName,
            "date": Timestamp(date: Date()),
            "year": CURRENT_YEAR,
            "createdAt": FieldValue.serverTimestamp(),
        ], forDocument: withdrawalRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .transfer, action: .add, description: "Withdrew \(formatPhp(amount)) from \(bankName)", amount: amount)
    }
}
