import Foundation
import FirebaseFirestore

struct BuySellService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("buySellTransactions")
    }

    static func subscribe(uid: String, year: Int, onChange: @escaping ([BuySellTransaction]) -> Void) -> ListenerRegistration {
        col(uid)
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let txs = docs.compactMap { try? $0.data(as: BuySellTransaction.self) }
                    .sorted { $0.order > $1.order }
                onChange(txs)
            }
    }

    @discardableResult
    static func add(uid: String, tx: BuySellTransaction) async throws -> String {
        let buyPrice = tx.fundingSources.reduce(0.0) { $0 + $1.amount }
        let profit = tx.sellPrice.map { $0 - buyPrice }
        let txDocId = col(uid).document().documentID
        let ref = col(uid).document(txDocId)

        let batch = db.batch()

        // Deduct from each funding source wallet
        for src in tx.fundingSources {
            let walletRef = db.collection("users").document(uid).collection("wallets").document(src.sourceId)
            batch.updateData([
                "balance": FieldValue.increment(-src.amount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: walletRef)
        }

        // Create transaction doc
        let fundingData = tx.fundingSources.map { [
            "sourceId": $0.sourceId,
            "sourceName": $0.sourceName,
            "amount": $0.amount
        ] as [String: Any] }

        var data: [String: Any] = [
            "itemName": tx.itemName,
            "itemType": tx.itemType.rawValue,
            "buyPrice": buyPrice,
            "fundingSources": fundingData,
            "status": tx.status.rawValue,
            "notes": tx.notes,
            "year": tx.year,
            "order": Date().timeIntervalSince1970 * 1000,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        if let sellPrice = tx.sellPrice { data["sellPrice"] = sellPrice }
        if let profit = profit { data["profit"] = profit }
        if let buyerName = tx.buyerName, !buyerName.isEmpty { data["buyerName"] = buyerName }
        if let dateBought = tx.dateBought { data["dateBought"] = Timestamp(date: dateBought) }
        if let dateSold = tx.dateSold { data["dateSold"] = Timestamp(date: dateSold) }

        batch.setData(data, forDocument: ref)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .buySell, action: .add, description: "Added B&S: \(tx.itemName)", amount: buyPrice)
        return txDocId
    }

    static func update(uid: String, txId: String, oldFundingSources: [FundingSource], tx: BuySellTransaction) async throws {
        let buyPrice = tx.fundingSources.reduce(0.0) { $0 + $1.amount }
        let profit = tx.sellPrice.map { $0 - buyPrice }
        let txRef = col(uid).document(txId)

        let batch = db.batch()

        // Compute net change per wallet using FieldValue.increment
        // First, build a map of sourceId -> net delta
        var deltaMap: [String: Double] = [:]
        for old in oldFundingSources {
            deltaMap[old.sourceId, default: 0] += old.amount // restore old
        }
        for src in tx.fundingSources {
            deltaMap[src.sourceId, default: 0] -= src.amount // apply new
        }

        for (sourceId, delta) in deltaMap where delta != 0 {
            let walletRef = db.collection("users").document(uid).collection("wallets").document(sourceId)
            batch.updateData([
                "balance": FieldValue.increment(delta),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: walletRef)
        }

        let fundingData = tx.fundingSources.map { [
            "sourceId": $0.sourceId,
            "sourceName": $0.sourceName,
            "amount": $0.amount
        ] as [String: Any] }

        var data: [String: Any] = [
            "itemName": tx.itemName,
            "itemType": tx.itemType.rawValue,
            "buyPrice": buyPrice,
            "fundingSources": fundingData,
            "status": tx.status.rawValue,
            "notes": tx.notes,
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        if let sellPrice = tx.sellPrice { data["sellPrice"] = sellPrice } else { data["sellPrice"] = NSNull() }
        if let profit = profit { data["profit"] = profit } else { data["profit"] = NSNull() }
        if let buyerName = tx.buyerName, !buyerName.isEmpty { data["buyerName"] = buyerName } else { data["buyerName"] = NSNull() }
        if let dateBought = tx.dateBought { data["dateBought"] = Timestamp(date: dateBought) }
        if let dateSold = tx.dateSold { data["dateSold"] = Timestamp(date: dateSold) }

        batch.updateData(data, forDocument: txRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .buySell, action: .edit, description: "Updated B&S: \(tx.itemName)", amount: buyPrice)
    }

    static func markAsSold(uid: String, txId: String, buyPrice: Double, sellPrice: Double, buyerName: String, dateSold: Date, soldDestinations: [FundingSource]) {
        let txRef = col(uid).document(txId)
        let profit = sellPrice - buyPrice
        let batch = db.batch()

        // Credit each destination wallet
        for dest in soldDestinations {
            let walletRef = db.collection("users").document(uid).collection("wallets").document(dest.sourceId)
            batch.updateData([
                "balance": FieldValue.increment(dest.amount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: walletRef)
        }

        let destData = soldDestinations.map { [
            "sourceId": $0.sourceId,
            "sourceName": $0.sourceName,
            "amount": $0.amount
        ] as [String: Any] }

        var data: [String: Any] = [
            "sellPrice": sellPrice,
            "profit": profit,
            "dateSold": Timestamp(date: dateSold),
            "soldDestinations": destData,
            "status": BuySellStatus.sold.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if !buyerName.isEmpty { data["buyerName"] = buyerName }

        batch.updateData(data, forDocument: txRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .buySell, action: .edit, description: "Sold item for \(sellPrice)", amount: sellPrice)
    }

    static func delete(uid: String, txId: String, fundingSources: [FundingSource]) async throws {
        let txRef = col(uid).document(txId)

        let batch = db.batch()

        // Restore funding source wallets
        for src in fundingSources {
            guard !src.sourceId.isEmpty else { continue }
            let walletRef = db.collection("users").document(uid).collection("wallets").document(src.sourceId)
            batch.updateData([
                "balance": FieldValue.increment(src.amount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: walletRef)
        }

        batch.deleteDocument(txRef)

        batch.commit(completion: nil)
        let totalAmount = fundingSources.reduce(0.0) { $0 + $1.amount }
        ActivityLogService.log(uid: uid, type: .buySell, action: .delete, description: "Deleted B&S transaction", amount: totalAmount)
    }
}
