import Foundation
import FirebaseFirestore

struct SavingsService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("savingsBreakdown")
    }

    static func subscribe(uid: String, year: Int, onChange: @escaping ([SavingsBreakdown]) -> Void) -> ListenerRegistration {
        col(uid)
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let items = docs.compactMap { try? $0.data(as: SavingsBreakdown.self) }
                onChange(items)
            }
    }

    static func add(uid: String, item: SavingsBreakdown) async throws {
        try await col(uid).addDocument(data: [
            "label": item.label,
            "amount": item.amount,
            "year": item.year,
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }

    static func update(uid: String, itemId: String, data: [String: Any]) async throws {
        var data = data
        data["updatedAt"] = FieldValue.serverTimestamp()
        try await col(uid).document(itemId).updateData(data)
    }

    static func delete(uid: String, itemId: String) async throws {
        try await col(uid).document(itemId).delete()
    }
}
