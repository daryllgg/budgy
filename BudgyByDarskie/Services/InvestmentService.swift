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

    static func tpsl(uid: String, exit: InvestmentExit) {
        let batch = db.batch()

        // Credit each destination wallet
        for dest in exit.destinations {
            let walletRef = db.collection("users").document(uid).collection("wallets").document(dest.sourceId)
            batch.updateData([
                "balance": FieldValue.increment(dest.amount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: walletRef)
        }

        // Mark the investment as exited
        let investmentRef = col(uid).document(exit.investmentId)
        batch.updateData([
            "exited": true,
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: investmentRef)

        // Store the exit record
        let exitRef = db.collection("users").document(uid).collection("investmentExits").document()
        let destData = exit.destinations.map { [
            "sourceId": $0.sourceId,
            "sourceName": $0.sourceName,
            "amount": $0.amount
        ] as [String: Any] }

        batch.setData([
            "investmentId": exit.investmentId,
            "stock": exit.stock,
            "investmentType": exit.investmentType.rawValue,
            "amountInvested": exit.amountInvested,
            "amountOut": exit.amountOut,
            "profit": exit.profit,
            "destinations": destData,
            "date": Timestamp(date: exit.date),
            "notes": exit.notes,
            "year": exit.year,
            "createdAt": FieldValue.serverTimestamp(),
        ], forDocument: exitRef)

        batch.commit(completion: nil)
        let action = exit.profit >= 0 ? "TP" : "SL"
        ActivityLogService.log(uid: uid, type: .investment, action: .edit, description: "\(action): \(exit.stock) → \(formatPhp(exit.amountOut))", amount: exit.amountOut)
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
