import Foundation
import FirebaseFirestore

struct ActivityLogService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("activityLog")
    }

    static func log(uid: String, type: ActivityLogType, action: ActivityLogAction, description: String, amount: Double? = nil) {
        var data: [String: Any] = [
            "type": type.rawValue,
            "action": action.rawValue,
            "description": description,
            "year": CURRENT_YEAR,
            "createdAt": FieldValue.serverTimestamp(),
        ]
        if let amount { data["amount"] = amount }
        col(uid).addDocument(data: data, completion: nil)
    }

    static func subscribe(uid: String, limit: Int = 200, onChange: @escaping ([ActivityLog]) -> Void) -> ListenerRegistration {
        col(uid)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let logs = docs.compactMap { try? $0.data(as: ActivityLog.self) }
                onChange(logs)
            }
    }
}
