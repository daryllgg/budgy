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

    static func transfer(uid: String, sourceWalletId: String, destWalletId: String, amount: Double, fee: Double, sourceName: String) async throws {
        let sourceRef = col(uid).document(sourceWalletId)
        let destRef = col(uid).document(destWalletId)
        let expenseCol = db.collection("users").document(uid).collection("expenses")
        let withdrawalCol = db.collection("users").document(uid).collection("withdrawals")

        // Get destination wallet name
        let destDoc = try? await destRef.getDocument()
        let destWalletName = destDoc?.data()?["name"] as? String ?? "Wallet"

        let batch = db.batch()

        // Deduct amount + fee from source
        batch.updateData([
            "balance": FieldValue.increment(-(amount + fee)),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: sourceRef)

        // Add amount to destination
        batch.updateData([
            "balance": FieldValue.increment(amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: destRef)

        // Add fee as expense
        if fee > 0 {
            let expenseRef = expenseCol.document()
            batch.setData([
                "description": "Transfer Fee",
                "amount": fee,
                "date": Timestamp(date: Date()),
                "category": ExpenseCategory.other.rawValue,
                "sourceId": sourceWalletId,
                "sourceName": sourceName,
                "notes": "Transfer fee",
                "year": CURRENT_YEAR,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
            ], forDocument: expenseRef)
        }

        // Log transfer record (uses same withdrawals collection for backward compat)
        let withdrawalRef = withdrawalCol.document()
        batch.setData([
            "amount": amount,
            "fee": fee,
            "bankWalletId": sourceWalletId,
            "bankWalletName": sourceName,
            "cashWalletId": destWalletId,
            "cashWalletName": destWalletName,
            "date": Timestamp(date: Date()),
            "year": CURRENT_YEAR,
            "createdAt": FieldValue.serverTimestamp(),
        ], forDocument: withdrawalRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .transfer, action: .add, description: "Transferred \(formatPhp(amount)) from \(sourceName) to \(destWalletName)", amount: amount)
    }
}
