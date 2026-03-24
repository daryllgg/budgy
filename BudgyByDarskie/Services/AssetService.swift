import Foundation
import FirebaseFirestore

struct AssetService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("assets")
    }

    static func subscribe(uid: String, year: Int, onChange: @escaping ([Asset]) -> Void) -> ListenerRegistration {
        col(uid)
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let assets = docs.compactMap { try? $0.data(as: Asset.self) }
                    .sorted { ($0.category.rawValue, $0.order) < ($1.category.rawValue, $1.order) }
                onChange(assets)
            }
    }

    @discardableResult
    static func add(uid: String, asset: Asset) async throws -> String {
        let assetDocId = col(uid).document().documentID
        let assetRef = col(uid).document(assetDocId)
        let assetData: [String: Any] = [
            "name": asset.name,
            "category": asset.category.rawValue,
            "amount": asset.amount,
            "sourceId": asset.sourceId,
            "sourceName": asset.sourceName,
            "notes": asset.notes,
            "year": asset.year,
            "order": Date().timeIntervalSince1970 * 1000,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        if asset.sourceId.isEmpty {
            assetRef.setData(assetData, completion: nil)
            ActivityLogService.log(uid: uid, type: .asset, action: .add, description: "Added asset: \(asset.name)", amount: asset.amount)
            return assetDocId
        }

        let walletRef = db.collection("users").document(uid).collection("wallets").document(asset.sourceId)

        let batch = db.batch()

        batch.updateData([
            "balance": FieldValue.increment(-asset.amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: walletRef)

        batch.setData(assetData, forDocument: assetRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .asset, action: .add, description: "Added asset: \(asset.name)", amount: asset.amount)
        return assetDocId
    }

    static func update(uid: String, assetId: String, oldAmount: Double, oldSourceId: String, asset: Asset) async throws {
        let oldWalletRef = db.collection("users").document(uid).collection("wallets").document(oldSourceId)
        let newWalletRef = db.collection("users").document(uid).collection("wallets").document(asset.sourceId)
        let assetRef = col(uid).document(assetId)

        let batch = db.batch()

        if oldSourceId == asset.sourceId {
            batch.updateData([
                "balance": FieldValue.increment(oldAmount - asset.amount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: oldWalletRef)
        } else {
            batch.updateData([
                "balance": FieldValue.increment(oldAmount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: oldWalletRef)

            batch.updateData([
                "balance": FieldValue.increment(-asset.amount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: newWalletRef)
        }

        batch.updateData([
            "name": asset.name,
            "category": asset.category.rawValue,
            "amount": asset.amount,
            "sourceId": asset.sourceId,
            "sourceName": asset.sourceName,
            "notes": asset.notes,
            "updatedAt": FieldValue.serverTimestamp(),
        ], forDocument: assetRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .asset, action: .edit, description: "Updated asset: \(asset.name)", amount: asset.amount)
    }

    static func delete(uid: String, assetId: String, sourceId: String, amount: Double) async throws {
        let assetRef = col(uid).document(assetId)

        if sourceId.isEmpty {
            assetRef.delete(completion: nil)
            ActivityLogService.log(uid: uid, type: .asset, action: .delete, description: "Deleted asset", amount: amount)
            return
        }

        let walletRef = db.collection("users").document(uid).collection("wallets").document(sourceId)

        let batch = db.batch()

        batch.updateData([
            "balance": FieldValue.increment(amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: walletRef)

        batch.deleteDocument(assetRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .asset, action: .delete, description: "Deleted asset", amount: amount)
    }
}
