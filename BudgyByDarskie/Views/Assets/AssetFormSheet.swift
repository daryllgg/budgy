import SwiftUI

struct AssetFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let wallets: [Wallet]
    let onSave: (Asset) async -> Void

    @State private var name = ""
    @State private var category: AssetCategory = .cellphone
    @State private var amount = ""
    @State private var sourceId = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage = ""

    private let existingAsset: Asset?

    init(wallets: [Wallet], asset: Asset? = nil, onSave: @escaping (Asset) async -> Void) {
        self.wallets = wallets
        self.existingAsset = asset
        self.onSave = onSave
        if let a = asset {
            _name = State(initialValue: a.name)
            _category = State(initialValue: a.category)
            _amount = State(initialValue: String(a.amount))
            _sourceId = State(initialValue: a.sourceId)
            _notes = State(initialValue: a.notes)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Category", selection: $category) {
                    ForEach(AssetCategory.allCases, id: \.self) { cat in
                        Label(cat.label, systemImage: cat.icon).tag(cat)
                    }
                }
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                Picker("Source Wallet", selection: $sourceId) {
                    Text("None (Historical)").tag("")
                    ForEach(wallets) { w in
                        Text("\(w.name) (\(formatPhp(w.balance)))").tag(w.id ?? "")
                    }
                }
                TextField("Notes", text: $notes)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(existingAsset == nil ? "Add Asset" : "Edit Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let enteredAmount = Double(amount) ?? 0
                        let wallet = wallets.first(where: { $0.id == sourceId })
                        let oldAmount = existingAsset?.amount ?? 0
                        let availableBalance = (wallet?.balance ?? 0) + (existingAsset?.sourceId == sourceId ? oldAmount : 0)

                        if !sourceId.isEmpty && enteredAmount > availableBalance {
                            errorMessage = "Insufficient balance. Available: \(formatPhp(availableBalance))"
                            return
                        }
                        errorMessage = ""
                        isSaving = true
                        Task {
                            let asset = Asset(
                                name: name,
                                category: category,
                                amount: enteredAmount,
                                sourceId: sourceId,
                                sourceName: wallet?.name ?? "",
                                notes: notes,
                                year: CURRENT_YEAR,
                                order: existingAsset?.order ?? 0
                            )
                            await onSave(asset)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || amount.isEmpty || (Double(amount) ?? 0) <= 0 || isSaving)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
