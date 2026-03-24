import SwiftUI

struct DepositFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let wallet: Wallet
    let onSave: (Deposit) async -> Void

    @State private var amount = ""
    @State private var source: DepositSource = .salary
    @State private var sourceLabel = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Deposit to \(wallet.name)") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Source", selection: $source) {
                        ForEach(DepositSource.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    if source == .other {
                        TextField("Source Label", text: $sourceLabel)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("Deposit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Deposit") {
                        isSaving = true
                        Task {
                            let deposit = Deposit(
                                amount: Double(amount) ?? 0,
                                source: source,
                                sourceLabel: source == .other ? sourceLabel : source.label,
                                walletId: wallet.id ?? "",
                                walletName: wallet.name,
                                date: date,
                                notes: notes,
                                year: CURRENT_YEAR
                            )
                            await onSave(deposit)
                            dismiss()
                        }
                    }
                    .disabled(amount.isEmpty || (Double(amount) ?? 0) <= 0 || isSaving)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
