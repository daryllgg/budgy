import Foundation
import FirebaseFirestore

struct ClearDataService {
    nonisolated(unsafe) private static let db = Firestore.firestore()
    private static let batchLimit = 500

    static func clearAllUserData(uid: String) async throws {
        let userDoc = db.collection("users").document(uid)

        // Delete payments subcollections under each receivable
        let receivables = try await userDoc.collection("receivables").getDocuments()
        for doc in receivables.documents {
            try await deleteCollection(doc.reference.collection("payments"))
        }

        // Delete all top-level collections
        let collections = [
            "assets", "wallets", "deposits", "receivables",
            "expenses", "buySellTransactions", "profitAllocations",
            "investments", "savingsBreakdown"
        ]
        for name in collections {
            try await deleteCollection(userDoc.collection(name))
        }
    }

    private static func deleteCollection(_ ref: CollectionReference) async throws {
        let snapshot = try await ref.getDocuments()
        guard !snapshot.isEmpty else { return }

        var batch = db.batch()
        var count = 0

        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
            count += 1
            if count >= batchLimit {
                try await batch.commit()
                batch = db.batch()
                count = 0
            }
        }

        if count > 0 {
            try await batch.commit()
        }
    }
}
