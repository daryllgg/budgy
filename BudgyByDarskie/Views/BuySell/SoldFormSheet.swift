import SwiftUI

struct SoldFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let transaction: BuySellTransaction
    let wallets: [Wallet]
    let onSold: (Double, String, Date, [FundingSource]) -> Void

    @State private var sellPrice = ""
    @State private var buyerName = ""
    @State private var dateSold = Date()
    @State private var destinations: [FundingSource] = []
    @State private var newDestId = ""
    @State private var newDestAmount = ""
    @State private var errorMessage = ""
    @State private var isSaving = false

    private var sellPriceValue: Double? { Double(sellPrice) }
    private var destinationsTotal: Double { destinations.reduce(0) { $0 + $1.amount } }
    private var remainingToAllocate: Double { (sellPriceValue ?? 0) - destinationsTotal }

    private var canSave: Bool {
        guard let sp = sellPriceValue, sp > 0 else { return false }
        guard !destinations.isEmpty else { return false }
        guard abs(destinationsTotal - sp) < 0.01 else { return false }
        return !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                // Item info (read-only)
                Section {
                    LabeledContent("Item", value: transaction.itemName)
                    LabeledContent("Buy Price", value: formatPhp(transaction.buyPrice))
                }

                // Sale details
                Section("Sale Details") {
                    TextField("Sell Price", text: $sellPrice)
                        .keyboardType(.decimalPad)
                    TextField("Buyer Name", text: $buyerName)
                    DatePicker("Date Sold", selection: $dateSold, displayedComponents: .date)
                }

                // Destination wallets
                Section("Deposit To (Wallets)") {
                    ForEach(destinations) { dest in
                        HStack {
                            Text(dest.sourceName)
                            Spacer()
                            Text(formatPhp(dest.amount))
                                .monospacedDigit()
                            Button { destinations.removeAll(where: { $0.sourceId == dest.sourceId }) } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    Picker("Wallet", selection: $newDestId) {
                        Text("Select Wallet").tag("")
                        ForEach(wallets) { w in
                            Text(w.name).tag(w.id ?? "")
                        }
                    }

                    TextField("Amount", text: $newDestAmount)
                        .keyboardType(.decimalPad)

                    Button {
                        guard !newDestId.isEmpty else {
                            errorMessage = "Select a wallet first"
                            return
                        }
                        guard let amt = Double(newDestAmount), amt > 0 else {
                            errorMessage = "Enter a valid amount"
                            return
                        }
                        guard amt <= remainingToAllocate + 0.01 else {
                            errorMessage = "Amount exceeds remaining \(formatPhp(remainingToAllocate))"
                            return
                        }
                        errorMessage = ""
                        let name = wallets.first(where: { $0.id == newDestId })?.name ?? ""
                        destinations.append(FundingSource(sourceId: newDestId, sourceName: name, amount: amt))
                        newDestId = ""
                        newDestAmount = ""
                    } label: {
                        Label("Add Destination", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if let sp = sellPriceValue, sp > 0 {
                        HStack {
                            Text("Allocated")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(formatPhp(destinationsTotal)) / \(formatPhp(sp))")
                                .monospacedDigit()
                                .foregroundStyle(abs(destinationsTotal - sp) < 0.01 ? .green : .orange)
                        }
                        .font(.caption)
                    }
                }

                // Profit preview
                if let sp = sellPriceValue {
                    Section("Profit Preview") {
                        let profit = sp - transaction.buyPrice
                        HStack {
                            Text("Profit")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatPhp(profit))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(profit >= 0 ? AppTheme.positive : AppTheme.negative)
                        }
                    }
                }
            }
            .navigationTitle("Mark as Sold")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm Sale") {
                        guard let sp = sellPriceValue else { return }
                        isSaving = true
                        onSold(sp, buyerName, dateSold, destinations)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
    }
}
