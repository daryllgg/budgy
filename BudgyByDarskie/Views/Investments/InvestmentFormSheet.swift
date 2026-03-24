import SwiftUI

struct InvestmentFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let wallets: [Wallet]
    let onSave: (Investment) async -> Void

    @State private var date = Date()
    @State private var investmentType: InvestmentType = .stock
    @State private var source: InvestmentSource = .salary
    @State private var sourceId = ""
    @State private var stock = "VOO"
    @State private var amountPhp = ""
    @State private var amountUsd = ""
    @State private var buyPrice = ""
    @State private var quantity = ""
    @State private var remarks = ""
    @State private var isSaving = false
    @State private var errorMessage = ""

    private let existingInvestment: Investment?

    init(wallets: [Wallet], investment: Investment? = nil, onSave: @escaping (Investment) async -> Void) {
        self.wallets = wallets
        self.existingInvestment = investment
        self.onSave = onSave
        if let i = investment {
            _date = State(initialValue: i.date)
            _investmentType = State(initialValue: i.investmentType)
            _source = State(initialValue: i.source)
            _sourceId = State(initialValue: i.sourceId)
            _stock = State(initialValue: i.stock)
            _amountPhp = State(initialValue: String(i.amountPhp))
            _amountUsd = State(initialValue: String(i.amountUsd))
            _buyPrice = State(initialValue: String(i.buyPrice))
            _quantity = State(initialValue: String(i.quantity))
            _remarks = State(initialValue: i.remarks)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Type", selection: $investmentType) {
                    ForEach(InvestmentType.allCases, id: \.self) { t in
                        Text(t.label).tag(t)
                    }
                }
                Picker("Source", selection: $source) {
                    ForEach(InvestmentSource.allCases, id: \.self) { s in
                        Text(s.label).tag(s)
                    }
                }
                Picker("Source Wallet", selection: $sourceId) {
                    Text("Select").tag("")
                    ForEach(wallets) { w in
                        Text("\(w.name) (\(formatPhp(w.balance)))").tag(w.id ?? "")
                    }
                }
                TextField("Stock/Asset", text: $stock)
                TextField("Amount (PHP)", text: $amountPhp)
                    .keyboardType(.decimalPad)
                TextField("Amount (USD)", text: $amountUsd)
                    .keyboardType(.decimalPad)
                TextField("Buy Price", text: $buyPrice)
                    .keyboardType(.decimalPad)
                TextField("Quantity", text: $quantity)
                    .keyboardType(.decimalPad)
                TextField("Remarks", text: $remarks)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(existingInvestment == nil ? "Add Investment" : "Edit Investment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let enteredAmount = Double(amountPhp) ?? 0
                        let wallet = wallets.first(where: { $0.id == sourceId })
                        let oldAmount = existingInvestment?.amountPhp ?? 0
                        let availableBalance = (wallet?.balance ?? 0) + (existingInvestment?.sourceId == sourceId ? oldAmount : 0)

                        if !sourceId.isEmpty && enteredAmount > availableBalance {
                            errorMessage = "Insufficient balance. Available: \(formatPhp(availableBalance))"
                            return
                        }
                        errorMessage = ""
                        isSaving = true
                        Task {
                            let inv = Investment(
                                date: date,
                                investmentType: investmentType,
                                source: source,
                                sourceId: sourceId,
                                sourceName: wallet?.name ?? "",
                                stock: stock,
                                amountPhp: enteredAmount,
                                amountUsd: Double(amountUsd) ?? 0,
                                buyPrice: Double(buyPrice) ?? 0,
                                quantity: Double(quantity) ?? 0,
                                remarks: remarks,
                                year: CURRENT_YEAR
                            )
                            await onSave(inv)
                            dismiss()
                        }
                    }
                    .disabled(sourceId.isEmpty || amountPhp.isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.large])
    }
}
