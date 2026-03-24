import SwiftUI

struct WalletFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Wallet) async -> Void

    @State private var name = ""
    @State private var type: WalletType = .bank
    @State private var bankName = ""
    @State private var balance: String = ""
    @State private var notes = ""
    @State private var isSaving = false

    private let existingWallet: Wallet?

    init(wallet: Wallet? = nil, onSave: @escaping (Wallet) async -> Void) {
        self.existingWallet = wallet
        self.onSave = onSave
        if let w = wallet {
            _name = State(initialValue: w.name)
            _type = State(initialValue: w.type)
            _bankName = State(initialValue: w.bankName)
            _balance = State(initialValue: String(w.balance))
            _notes = State(initialValue: w.notes)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Type", selection: $type) {
                    ForEach(WalletType.allCases, id: \.self) { t in
                        Text(t.label).tag(t)
                    }
                }
                if type == .bank {
                    Picker("Bank", selection: $bankName) {
                        Text("Select").tag("")
                        ForEach(KNOWN_BANKS, id: \.self) { bank in
                            Text(bank).tag(bank)
                        }
                    }
                }
                TextField("Balance", text: $balance)
                    .keyboardType(.decimalPad)
                TextField("Notes", text: $notes)
            }
            .navigationTitle(existingWallet == nil ? "Add Wallet" : "Edit Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            let wallet = Wallet(
                                name: name,
                                type: type,
                                bankName: type == .bank ? bankName : "",
                                balance: Double(balance) ?? 0,
                                notes: notes,
                                year: CURRENT_YEAR,
                                order: existingWallet?.order ?? 0
                            )
                            await onSave(wallet)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || (Double(balance) ?? 0) < 0 || isSaving)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
