import AppIntents

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description: IntentDescription = "Quickly add a new expense in Budgy"
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AddExpenseIntent.pendingAction = true
        return .result()
    }

    @MainActor static var pendingAction = false
}

struct BudgyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add expense in \(.applicationName)",
                "Log expense in \(.applicationName)",
                "New expense in \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "dollarsign.circle.fill"
        )
    }
}
