import Foundation
import FirebaseFirestore

struct ExpenseService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func col(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("expenses")
    }

    static func subscribe(uid: String, year: Int, onChange: @escaping ([Expense]) -> Void) -> ListenerRegistration {
        col(uid)
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let expenses = docs.compactMap { try? $0.data(as: Expense.self) }
                    .sorted { $0.date > $1.date }
                onChange(expenses)
            }
    }

    @discardableResult
    static func add(uid: String, expense: Expense) async throws -> String {
        let walletRef = db.collection("users").document(uid).collection("wallets").document(expense.sourceId)
        let expenseDocId = col(uid).document().documentID
        let expenseRef = col(uid).document(expenseDocId)

        let batch = db.batch()

        batch.updateData([
            "balance": FieldValue.increment(-expense.amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: walletRef)

        batch.setData([
            "description": expense.expenseDescription,
            "amount": expense.amount,
            "date": Timestamp(date: expense.date),
            "category": expense.category.rawValue,
            "sourceId": expense.sourceId,
            "sourceName": expense.sourceName,
            "notes": expense.notes,
            "year": expense.year,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ], forDocument: expenseRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .expense, action: .add, description: "Added expense: \(expense.expenseDescription)", amount: expense.amount)
        return expenseDocId
    }

    static func update(uid: String, expenseId: String, oldAmount: Double, oldSourceId: String, expense: Expense) async throws {
        let oldWalletRef = db.collection("users").document(uid).collection("wallets").document(oldSourceId)
        let newWalletRef = db.collection("users").document(uid).collection("wallets").document(expense.sourceId)
        let expenseRef = col(uid).document(expenseId)

        let batch = db.batch()

        if oldSourceId == expense.sourceId {
            batch.updateData([
                "balance": FieldValue.increment(oldAmount - expense.amount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: oldWalletRef)
        } else {
            batch.updateData([
                "balance": FieldValue.increment(oldAmount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: oldWalletRef)

            batch.updateData([
                "balance": FieldValue.increment(-expense.amount),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: newWalletRef)
        }

        batch.updateData([
            "description": expense.expenseDescription,
            "amount": expense.amount,
            "date": Timestamp(date: expense.date),
            "category": expense.category.rawValue,
            "sourceId": expense.sourceId,
            "sourceName": expense.sourceName,
            "notes": expense.notes,
            "updatedAt": FieldValue.serverTimestamp(),
        ], forDocument: expenseRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .expense, action: .edit, description: "Updated expense: \(expense.expenseDescription)", amount: expense.amount)
    }

    static func delete(uid: String, expenseId: String, sourceId: String, amount: Double) async throws {
        let walletRef = db.collection("users").document(uid).collection("wallets").document(sourceId)
        let expenseRef = col(uid).document(expenseId)

        let batch = db.batch()

        batch.updateData([
            "balance": FieldValue.increment(amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: walletRef)

        batch.deleteDocument(expenseRef)

        batch.commit(completion: nil)
        ActivityLogService.log(uid: uid, type: .expense, action: .delete, description: "Deleted expense", amount: amount)
    }
}
