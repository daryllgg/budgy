import SwiftUI
import FirebaseFirestore

@Observable
class ExpenseViewModel {
    var recentExpenses: [Expense] = []
    var olderExpenses: [Expense] = []
    var isLoading = true
    var isLoadingMore = false
    var hasMoreData = true
    var errorMessage: String?

    private var listener: ListenerRegistration?
    private var lastDocument: DocumentSnapshot?
    private var sinceDate: Date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    private var currentYear: Int = CURRENT_YEAR

    var expenses: [Expense] {
        let allIds = Set(recentExpenses.compactMap(\.id))
        let dedupedOlder = olderExpenses.filter { expense in
            guard let id = expense.id else { return true }
            return !allIds.contains(id)
        }
        return (recentExpenses + dedupedOlder).sorted { $0.date > $1.date }
    }

    var totalExpenses: Double { expenses.reduce(0) { $0 + $1.amount } }

    var byCategory: [ExpenseCategory: Double] {
        Dictionary(grouping: expenses, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    func subscribe(uid: String, year: Int = CURRENT_YEAR) {
        listener?.remove()
        isLoading = true
        olderExpenses = []
        lastDocument = nil
        hasMoreData = true
        currentYear = year
        sinceDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!

        listener = ExpenseService.subscribeRecent(uid: uid, year: year, since: sinceDate) { [weak self] expenses in
            guard let self else { return }
            withAnimation {
                self.recentExpenses = expenses
                self.isLoading = false
            }
        }
    }

    func loadMore(uid: String) async {
        guard !isLoadingMore, hasMoreData else { return }
        isLoadingMore = true

        do {
            let result = try await ExpenseService.fetchOlderPage(
                uid: uid,
                year: currentYear,
                before: sinceDate,
                lastDocument: lastDocument,
                limit: 20
            )
            withAnimation {
                olderExpenses.append(contentsOf: result.expenses)
                lastDocument = result.lastDoc
                if result.expenses.count < 20 {
                    hasMoreData = false
                }
                isLoadingMore = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoadingMore = false
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
