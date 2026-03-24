import SwiftUI

struct ExpenseFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let wallets: [Wallet]
    let onSave: (Expense) async -> Void

    @State private var description = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var category: ExpenseCategory = .food
    @State private var sourceId = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage = ""

    private let existingExpense: Expense?

    init(wallets: [Wallet], expense: Expense? = nil, scanResult: ReceiptScanResult? = nil, onSave: @escaping (Expense) async -> Void) {
        self.wallets = wallets
        self.existingExpense = expense
        self.onSave = onSave
        if let e = expense {
            _description = State(initialValue: e.expenseDescription)
            _amount = State(initialValue: String(e.amount))
            _date = State(initialValue: e.date)
            _category = State(initialValue: e.category)
            _sourceId = State(initialValue: e.sourceId)
            _notes = State(initialValue: e.notes)
        } else if let scan = scanResult {
            _description = State(initialValue: scan.description ?? "")
            _amount = State(initialValue: scan.amount ?? "")
            if let d = scan.date { _date = State(initialValue: d) }
            if let c = scan.category { _category = State(initialValue: c) }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Description", text: $description)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                        Label(cat.label, systemImage: cat.icon).tag(cat)
                    }
                }
                Picker("Source Wallet", selection: $sourceId) {
                    Text("Select").tag("")
                    ForEach(wallets) { wallet in
                        Text("\(wallet.name) (\(formatPhp(wallet.balance)))").tag(wallet.id ?? "")
                    }
                }
                TextField("Notes", text: $notes)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(existingExpense == nil ? "Add Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let enteredAmount = Double(amount) ?? 0
                        let wallet = wallets.first(where: { $0.id == sourceId })
                        let oldAmount = existingExpense?.amount ?? 0
                        let availableBalance = (wallet?.balance ?? 0) + (existingExpense?.sourceId == sourceId ? oldAmount : 0)

                        guard enteredAmount <= availableBalance else {
                            errorMessage = "Insufficient balance. Available: \(formatPhp(availableBalance))"
                            return
                        }
                        errorMessage = ""
                        isSaving = true
                        Task {
                            let expense = Expense(
                                expenseDescription: description,
                                amount: enteredAmount,
                                date: date,
                                category: category,
                                sourceId: sourceId,
                                sourceName: wallet?.name ?? "",
                                notes: notes,
                                year: CURRENT_YEAR
                            )
                            await onSave(expense)
                            dismiss()
                        }
                    }
                    .disabled(description.isEmpty || amount.isEmpty || (Double(amount) ?? 0) <= 0 || sourceId.isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.large])
    }
}
