import Foundation
import FirebaseFirestore

struct ReceivablePaymentService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String, _ receivableId: String) -> CollectionReference {
        db.collection("users").document(uid).collection("receivables")
            .document(receivableId).collection("payments")
    }

    static func subscribe(uid: String, receivableId: String, onChange: @escaping ([ReceivablePayment]) -> Void) -> ListenerRegistration {
        col(uid, receivableId)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let payments = docs.compactMap { try? $0.data(as: ReceivablePayment.self) }
                    .sorted { $0.date > $1.date }
                onChange(payments)
            }
    }

    static func add(uid: String, receivableId: String, payment: ReceivablePayment) async throws {
        let batch = db.batch()

        for dest in payment.destinations {
            let walletRef = db.collection("users").document(uid).collection("wallets").document(dest.walletId)
            batch.updateData([
                "balance": FieldValue.increment(dest.amount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: walletRef)
        }

        let receivableRef = db.collection("users").document(uid).collection("receivables").document(receivableId)
        batch.updateData([
            "totalPaid": FieldValue.increment(payment.amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: receivableRef)

        let destData = payment.destinations.map { [
            "walletId": $0.walletId,
            "walletName": $0.walletName,
            "amount": $0.amount
        ] as [String: Any] }

        let paymentRef = col(uid, receivableId).document()
        batch.setData([
            "amount": payment.amount,
            "date": Timestamp(date: payment.date),
            "destinations": destData,
            "notes": payment.notes,
            "createdAt": FieldValue.serverTimestamp(),
        ], forDocument: paymentRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .payment, action: .add, description: "Received payment", amount: payment.amount)
    }

    static func delete(uid: String, receivableId: String, payment: ReceivablePayment) async throws {
        guard let paymentId = payment.id else { return }

        let batch = db.batch()

        for dest in payment.destinations {
            let walletRef = db.collection("users").document(uid).collection("wallets").document(dest.walletId)
            batch.updateData([
                "balance": FieldValue.increment(-dest.amount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: walletRef)
        }

        let receivableRef = db.collection("users").document(uid).collection("receivables").document(receivableId)
        batch.updateData([
            "totalPaid": FieldValue.increment(-payment.amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: receivableRef)

        let paymentRef = col(uid, receivableId).document(paymentId)
        batch.deleteDocument(paymentRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .payment, action: .delete, description: "Deleted payment", amount: payment.amount)
    }
}
