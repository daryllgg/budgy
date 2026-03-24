import Foundation
import FirebaseFirestore

struct ReceivableService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("receivables")
    }

    static func subscribe(uid: String, year: Int, onChange: @escaping ([Receivable]) -> Void) -> ListenerRegistration {
        col(uid)
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let items = docs.compactMap { try? $0.data(as: Receivable.self) }
                    .sorted { $0.order < $1.order }
                onChange(items)
            }
    }

    @discardableResult
    static func add(uid: String, receivable: Receivable) async throws -> String {
        let receivableDocId = col(uid).document().documentID
        let receivableRef = col(uid).document(receivableDocId)
        let data: [String: Any] = [
            "name": receivable.name,
            "description": receivable.receivableDescription,
            "amount": receivable.amount,
            "sourceId": receivable.sourceId,
            "sourceName": receivable.sourceName,
            "isReimbursement": receivable.isReimbursement,
            "notes": receivable.notes,
            "year": receivable.year,
            "order": Date().timeIntervalSince1970 * 1000,
            "totalPaid": 0,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        if receivable.sourceId.isEmpty {
            try await receivableRef.setData(data)
            ActivityLogService.log(uid: uid, type: .receivable, action: .add, description: "Added receivable: \(receivable.name)", amount: receivable.amount)
            return receivableDocId
        }

        let walletRef = db.collection("users").document(uid).collection("wallets").document(receivable.sourceId)

        let batch = db.batch()

        batch.updateData([
            "balance": FieldValue.increment(-receivable.amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: walletRef)

        batch.setData(data, forDocument: receivableRef)

        try await batch.commit()
        ActivityLogService.log(uid: uid, type: .receivable, action: .add, description: "Added receivable: \(receivable.name)", amount: receivable.amount)
        return receivableDocId
    }

    static func update(uid: String, receivableId: String, data: [String: Any]) async throws {
        var data = data
        data["updatedAt"] = FieldValue.serverTimestamp()
        try await col(uid).document(receivableId).updateData(data)
        ActivityLogService.log(uid: uid, type: .receivable, action: .edit, description: "Updated receivable")
    }

    static func delete(uid: String, receivableId: String, sourceId: String = "", amount: Double = 0) async throws {
        if sourceId.isEmpty {
            try await col(uid).document(receivableId).delete()
            ActivityLogService.log(uid: uid, type: .receivable, action: .delete, description: "Deleted receivable")
            return
        }

        // Return funds to source wallet
        let walletRef = db.collection("users").document(uid).collection("wallets").document(sourceId)
        let batch = db.batch()

        batch.deleteDocument(col(uid).document(receivableId))
        batch.updateData([
            "balance": FieldValue.increment(amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: walletRef)

        try await batch.commit()
        ActivityLogService.log(uid: uid, type: .receivable, action: .delete, description: "Deleted receivable (funds returned)", amount: amount)
    }
}
