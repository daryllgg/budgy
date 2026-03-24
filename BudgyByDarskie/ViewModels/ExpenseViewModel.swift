import Foundation
import FirebaseFirestore

@Observable
class ExpenseViewModel {
    var expenses: [Expense] = []
    var isLoading = true
    var errorMessage: String?

    private var listener: ListenerRegistration?

    var totalExpenses: Double { expenses.reduce(0) { $0 + $1.amount } }

    var byCategory: [ExpenseCategory: Double] {
        Dictionary(grouping: expenses, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    func subscribe(uid: String, year: Int = CURRENT_YEAR) {
        listener?.remove()
        isLoading = true
        listener = ExpenseService.subscribe(uid: uid, year: year) { [weak self] expenses in
            self?.expenses = expenses
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
        listener = nil
    }

    func add(uid: String, expense: Expense) async -> String? {
        do {
            return try await ExpenseService.add(uid: uid, expense: expense)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func update(uid: String, expenseId: String, oldAmount: Double, oldSourceId: String, expense: Expense) async {
        do {
            try await ExpenseService.update(uid: uid, expenseId: expenseId, oldAmount: oldAmount, oldSourceId: oldSourceId, expense: expense)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(uid: String, expenseId: String, sourceId: String, amount: Double) async {
        do {
            try await ExpenseService.delete(uid: uid, expenseId: expenseId, sourceId: sourceId, amount: amount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
