import SwiftUI

struct ReceivableFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let wallets: [Wallet]
    let onSave: (Receivable) async -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var amount = ""
    @State private var sourceId = ""
    @State private var isReimbursement = false
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage = ""

    private let existingReceivable: Receivable?
    private let isNameLocked: Bool

    init(wallets: [Wallet], receivable: Receivable? = nil, prefillName: String? = nil, onSave: @escaping (Receivable) async -> Void) {
        self.wallets = wallets
        self.existingReceivable = receivable
        self.isNameLocked = prefillName != nil && receivable == nil
        self.onSave = onSave
        let availableWallets = wallets.filter { $0.balance > 0 }
        if let r = receivable {
            _name = State(initialValue: r.name)
            _description = State(initialValue: r.receivableDescription)
            _amount = State(initialValue: String(r.amount))
            _sourceId = State(initialValue: r.sourceId)
            _isReimbursement = State(initialValue: r.isReimbursement)
            _notes = State(initialValue: r.notes)
        } else {
            _sourceId = State(initialValue: availableWallets.first?.id ?? "")
            if let prefillName {
                _name = State(initialValue: prefillName)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if isNameLocked {
                    HStack {
                        Text("Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(name)
                    }
                } else {
                    TextField("Name", text: $name)
                }
                TextField("Description", text: $description)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                Picker("Source Wallet", selection: $sourceId) {
                    ForEach(wallets.filter { $0.balance > 0 }) { w in
                        Text("\(w.name) (\(formatPhp(w.balance)))").tag(w.id ?? "")
                    }
                }
                Toggle("Is Reimbursement", isOn: $isReimbursement)
                TextField("Notes", text: $notes)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(existingReceivable == nil ? "Add Receivable" : "Edit Receivable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let enteredAmount = Double(amount) ?? 0
                        let wallet = wallets.first(where: { $0.id == sourceId })
                        let oldAmount = existingReceivable?.amount ?? 0
                        let availableBalance = (wallet?.balance ?? 0) + (existingReceivable?.sourceId == sourceId ? oldAmount : 0)

                        guard enteredAmount <= availableBalance else {
                            errorMessage = "Insufficient balance. Available: \(formatPhp(availableBalance))"
                            return
                        }
                        errorMessage = ""
                        isSaving = true
                        Task {
                            let sourceName = wallet?.name ?? ""
                            let rec = Receivable(
                                name: name,
                                receivableDescription: description,
                                amount: enteredAmount,
                                sourceId: sourceId,
                                sourceName: sourceName,
                                isReimbursement: isReimbursement,
                                notes: notes,
                                year: CURRENT_YEAR,
                                order: existingReceivable?.order ?? 0
                            )
                            await onSave(rec)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || amount.isEmpty || (Double(amount) ?? 0) <= 0 || sourceId.isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
