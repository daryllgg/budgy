import SwiftUI

struct TPSLFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let investment: Investment
    let wallets: [Wallet]
    let onConfirm: (InvestmentExit) -> Void

    @State private var amountOut = ""
    @State private var dateSold = Date()
    @State private var notes = ""
    @State private var destinations: [FundingSource] = []
    @State private var newDestId = ""
    @State private var newDestAmount = ""
    @State private var errorMessage = ""
    @State private var isSaving = false

    private var amountOutValue: Double? { Double(amountOut) }
    private var destinationsTotal: Double { destinations.reduce(0) { $0 + $1.amount } }
    private var profit: Double { (amountOutValue ?? 0) - investment.amountPhp }
    private var remainingToAllocate: Double { (amountOutValue ?? 0) - destinationsTotal }

    private var canSave: Bool {
        guard let amt = amountOutValue, amt > 0 else { return false }
        guard !destinations.isEmpty else { return false }
        guard abs(destinationsTotal - amt) < 0.01 else { return false }
        return !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Asset", value: investment.stock)
                    LabeledContent("Invested", value: formatPhp(investment.amountPhp))
                }

                Section("Exit Details") {
                    TextField("Amount Out (Total Received)", text: $amountOut)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $dateSold, displayedComponents: .date)
                    TextField("Notes", text: $notes)
                }

                // Profit preview
                if let amt = amountOutValue, amt > 0 {
                    Section {
                        HStack {
                            Text(profit >= 0 ? "Profit" : "Loss")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatPhp(abs(profit)))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(profit >= 0 ? AppTheme.positive : AppTheme.negative)
                        }
                    }
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

                    if let amt = amountOutValue, amt > 0 {
                        HStack {
                            Text("Allocated")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(formatPhp(destinationsTotal)) / \(formatPhp(amt))")
                                .monospacedDigit()
                                .foregroundStyle(abs(destinationsTotal - amt) < 0.01 ? .green : .orange)
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("TP / SL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        guard let amt = amountOutValue else { return }
                        isSaving = true
                        let exit = InvestmentExit(
                            investmentId: investment.id ?? "",
                            stock: investment.stock,
                            investmentType: investment.investmentType,
                            amountInvested: investment.amountPhp,
                            amountOut: amt,
                            profit: profit,
                            destinations: destinations,
                            date: dateSold,
                            notes: notes,
                            year: CURRENT_YEAR
                        )
                        onConfirm(exit)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
    }
}
