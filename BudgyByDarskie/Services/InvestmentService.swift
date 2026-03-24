import Foundation
import FirebaseFirestore

struct InvestmentService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("investments")
    }

    static func subscribe(uid: String, year: Int?, onChange: @escaping ([Investment]) -> Void) -> ListenerRegistration {
        var query: Query = col(uid)
        if let year { query = query.whereField("year", isEqualTo: year) }

        return query.addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let investments = docs.compactMap { try? $0.data(as: Investment.self) }
                .sorted { $0.date > $1.date }
            onChange(investments)
        }
    }

    @discardableResult
    static func add(uid: String, investment: Investment) async throws -> String {
        let walletRef = db.collection("users").document(uid).collection("wallets").document(investment.sourceId)
        let investmentDocId = col(uid).document().documentID
        let ref = col(uid).document(investmentDocId)

        let batch = db.batch()

        batch.updateData([
            "balance": FieldValue.increment(-investment.amountPhp),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: walletRef)

        batch.setData([
            "date": Timestamp(date: investment.date),
            "investmentType": investment.investmentType.rawValue,
            "source": investment.source.rawValue,
            "sourceId": investment.sourceId,
            "sourceName": investment.sourceName,
            "stock": investment.stock,
            "amountPhp": investment.amountPhp,
            "amountUsd": investment.amountUsd,
            "buyPrice": investment.buyPrice,
            "quantity": investment.quantity,
            "remarks": investment.remarks,
            "year": investment.year,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ], forDocument: ref)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .investment, action: .add, description: "Added investment: \(investment.stock)", amount: investment.amountPhp)
        return investmentDocId
    }

    static func update(uid: String, investmentId: String, oldAmountPhp: Double, oldSourceId: String, investment: Investment) async throws {
        let oldWalletRef = db.collection("users").document(uid).collection("wallets").document(oldSourceId)
        let newWalletRef = db.collection("users").document(uid).collection("wallets").document(investment.sourceId)
        let investmentRef = col(uid).document(investmentId)

        let batch = db.batch()

        if oldSourceId == investment.sourceId {
            batch.updateData([
                "balance": FieldValue.increment(oldAmountPhp - investment.amountPhp),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: oldWalletRef)
        } else {
            batch.updateData([
                "balance": FieldValue.increment(oldAmountPhp),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: oldWalletRef)

            batch.updateData([
                "balance": FieldValue.increment(-investment.amountPhp),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: newWalletRef)
        }

        batch.updateData([
            "date": Timestamp(date: investment.date),
            "investmentType": investment.investmentType.rawValue,
            "source": investment.source.rawValue,
            "sourceId": investment.sourceId,
            "sourceName": investment.sourceName,
            "stock": investment.stock,
            "amountPhp": investment.amountPhp,
            "amountUsd": investment.amountUsd,
            "buyPrice": investment.buyPrice,
            "quantity": investment.quantity,
            "remarks": investment.remarks,
            "updatedAt": FieldValue.serverTimestamp(),
        ], forDocument: investmentRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .investment, action: .edit, description: "Updated investment: \(investment.stock)", amount: investment.amountPhp)
    }

    static func delete(uid: String, investmentId: String, sourceId: String, amountPhp: Double) async throws {
        let investmentRef = col(uid).document(investmentId)

        if sourceId.isEmpty {
            investmentRef.delete(completion: nil)
            return
        }

        let walletRef = db.collection("users").document(uid).collection("wallets").document(sourceId)

        let batch = db.batch()

        batch.updateData([
            "balance": FieldValue.increment(amountPhp),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: walletRef)

        batch.deleteDocument(investmentRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .investment, action: .delete, description: "Deleted investment", amount: amountPhp)
    }
}
