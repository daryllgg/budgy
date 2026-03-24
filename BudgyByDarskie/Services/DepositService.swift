import Foundation
import FirebaseFirestore

struct DepositService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("deposits")
    }

    static func subscribe(uid: String, year: Int, onChange: @escaping ([Deposit]) -> Void) -> ListenerRegistration {
        col(uid)
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let deposits = docs.compactMap { try? $0.data(as: Deposit.self) }
                    .sorted { $0.date > $1.date }
                onChange(deposits)
            }
    }

    @discardableResult
    static func add(uid: String, deposit: Deposit) async throws -> String {
        let walletRef = db.collection("users").document(uid).collection("wallets").document(deposit.walletId)
        let depositDocId = col(uid).document().documentID
        let depositRef = col(uid).document(depositDocId)

        let batch = db.batch()

        batch.updateData([
            "balance": FieldValue.increment(deposit.amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: walletRef)

        batch.setData([
            "amount": deposit.amount,
            "source": deposit.source.rawValue,
            "sourceLabel": deposit.sourceLabel,
            "walletId": deposit.walletId,
            "walletName": deposit.walletName,
            "date": Timestamp(date: deposit.date),
            "notes": deposit.notes,
            "year": deposit.year,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ], forDocument: depositRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .deposit, action: .add, description: "Deposited to \(deposit.walletName)", amount: deposit.amount)
        return depositDocId
    }

    static func delete(uid: String, depositId: String, walletId: String, amount: Double) async throws {
        let walletRef = db.collection("users").document(uid).collection("wallets").document(walletId)
        let depositRef = col(uid).document(depositId)

        let batch = db.batch()

        batch.updateData([
            "balance": FieldValue.increment(-amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: walletRef)

        batch.deleteDocument(depositRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .deposit, action: .delete, description: "Deleted deposit", amount: amount)
    }
}
