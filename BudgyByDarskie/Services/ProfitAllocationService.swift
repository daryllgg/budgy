import Foundation
import FirebaseFirestore

struct ProfitAllocationService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("profitAllocations")
    }

    static func subscribe(uid: String, year: Int, onChange: @escaping ([ProfitAllocation]) -> Void) -> ListenerRegistration {
        col(uid)
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let items = docs.compactMap { try? $0.data(as: ProfitAllocation.self) }
                    .sorted { $0.amount > $1.amount }
                onChange(items)
            }
    }

    static func add(uid: String, allocation: ProfitAllocation) async throws {
        try await col(uid).addDocument(data: [
            "label": allocation.label,
            "destType": allocation.destType,
            "amount": allocation.amount,
            "year": allocation.year,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }

    static func update(uid: String, allocationId: String, data: [String: Any]) async throws {
        var data = data
        data["updatedAt"] = FieldValue.serverTimestamp()
        try await col(uid).document(allocationId).updateData(data)
    }

    static func delete(uid: String, allocationId: String) async throws {
        try await col(uid).document(allocationId).delete()
    }
}
