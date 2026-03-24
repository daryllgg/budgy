import Foundation
import FirebaseFirestore

struct WatchlistService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("watchlist")
    }

    static func subscribe(uid: String, onChange: @escaping ([WatchlistItem]) -> Void) -> ListenerRegistration {
        col(uid)
            .order(by: "order")
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let items = docs.compactMap { try? $0.data(as: WatchlistItem.self) }
                onChange(items)
            }
    }

    @discardableResult
    static func add(uid: String, item: WatchlistItem) async throws -> String {
        let docId = col(uid).document().documentID
        let ref = col(uid).document(docId)
        ref.setData([
            "symbol": item.symbol,
            "name": item.name,
            "type": item.type.rawValue,
            "order": Date().timeIntervalSince1970 * 1000,
            "createdAt": FieldValue.serverTimestamp(),
        ], completion: nil)
        return docId
    }

    static func delete(uid: String, itemId: String) async throws {
        col(uid).document(itemId).delete(completion: nil)
    }
}
