import SwiftUI

struct BuySellFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let wallets: [Wallet]
    let onSave: (BuySellTransaction) async -> Void

    @State private var itemName = ""
    @State private var itemType: ItemType = .phone
    @State private var status: BuySellStatus = .available
    @State private var sellPrice = ""
    @State private var buyerName = ""
    @State private var dateBought = Date()
    @State private var dateSold = Date()
    @State private var hasSoldDate = false
    @State private var notes = ""
    @State private var fundingSources: [FundingSource] = []
    @State private var newSourceId = ""
    @State private var newSourceAmount = ""
    @State private var isSaving = false
    @State private var errorMessage = ""

    private let existingTx: BuySellTransaction?

    init(wallets: [Wallet], transaction: BuySellTransaction? = nil, onSave: @escaping (BuySellTransaction) async -> Void) {
        self.wallets = wallets
        self.existingTx = transaction
        self.onSave = onSave
        if let t = transaction {
            _itemName = State(initialValue: t.itemName)
            _itemType = State(initialValue: t.itemType)
            _status = State(initialValue: t.status)
            _sellPrice = State(initialValue: t.sellPrice.map { String($0) } ?? "")
            _buyerName = State(initialValue: t.buyerName ?? "")
            _dateBought = State(initialValue: t.dateBought ?? Date())
            _dateSold = State(initialValue: t.dateSold ?? Date())
            _hasSoldDate = State(initialValue: t.dateSold != nil)
            _notes = State(initialValue: t.notes)
            _fundingSources = State(initialValue: t.fundingSources)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Item Name", text: $itemName)
                    Picker("Type", selection: $itemType) {
                        ForEach(ItemType.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(BuySellStatus.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                }

                Section("Pricing") {
                    TextField("Sell Price", text: $sellPrice)
                        .keyboardType(.decimalPad)
                    TextField("Buyer Name", text: $buyerName)
                    DatePicker("Date Bought", selection: $dateBought, displayedComponents: .date)
                    Toggle("Has Sold Date", isOn: $hasSoldDate)
                    if hasSoldDate {
                        DatePicker("Date Sold", selection: $dateSold, displayedComponents: .date)
                    }
                }

                Section("Funding Sources (Buy Price)") {
                    ForEach(fundingSources) { src in
                        HStack {
                            Text(src.sourceName)
                            Spacer()
                            Text(formatPhp(src.amount))
                                .monospacedDigit()
                            Button { fundingSources.removeAll(where: { $0.sourceId == src.sourceId }) } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    HStack {
                        Picker("Wallet", selection: $newSourceId) {
                            Text("Select").tag("")
                            ForEach(wallets) { w in
                                Text("\(w.name) (\(formatPhp(w.balance)))").tag(w.id ?? "")
                            }
                        }
                        .labelsHidden()
                        TextField("Amount", text: $newSourceAmount)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                        Button {
                            guard let amt = Double(newSourceAmount), !newSourceId.isEmpty else { return }
                            let wallet = wallets.first(where: { $0.id == newSourceId })
                            let existingFromWallet = fundingSources.filter { $0.sourceId == newSourceId }.reduce(0) { $0 + $1.amount }
                            let oldFromWallet = existingTx?.fundingSources.filter { $0.sourceId == newSourceId }.reduce(0) { $0 + $1.amount } ?? 0
                            let available = (wallet?.balance ?? 0) + oldFromWallet - existingFromWallet

                            guard amt <= available else {
                                errorMessage = "Insufficient balance in \(wallet?.name ?? "wallet"). Available: \(formatPhp(available))"
                                return
                            }
                            errorMessage = ""
                            let name = wallet?.name ?? ""
                            fundingSources.append(FundingSource(sourceId: newSourceId, sourceName: name, amount: amt))
                            newSourceId = ""
                            newSourceAmount = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle(existingTx == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            let tx = BuySellTransaction(
                                itemName: itemName,
                                itemType: itemType,
                                buyPrice: fundingSources.reduce(0) { $0 + $1.amount },
                                sellPrice: Double(sellPrice),
                                profit: nil,
                                fundingSources: fundingSources,
                                buyerName: buyerName.isEmpty ? nil : buyerName,
                                dateBought: dateBought,
                                dateSold: hasSoldDate ? dateSold : nil,
                                status: status,
                                notes: notes,
                                year: CURRENT_YEAR,
                                order: existingTx?.order ?? 0
                            )
                            await onSave(tx)
                            dismiss()
                        }
                    }
                    .disabled(itemName.isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.large])
    }
}
