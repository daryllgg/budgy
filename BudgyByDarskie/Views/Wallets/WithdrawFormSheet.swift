import SwiftUI

struct TransferFormSheet: View {
    let sourceWallet: Wallet
    let allWallets: [Wallet]
    let onSubmit: (Double, Double, String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var fee = ""
    @State private var selectedDestId = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var transferAmount: Double { Double(amount) ?? 0 }
    private var feeAmount: Double { Double(fee) ?? 0 }
    private var totalDeduction: Double { transferAmount + feeAmount }
    private var destinationWallets: [Wallet] {
        allWallets.filter { $0.id != sourceWallet.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Transfer From") {
                    HStack {
                        Image(systemName: sourceWallet.type == .bank ? "building.columns.fill" : "banknote.fill")
                            .foregroundStyle(AppTheme.wallets)
                        Text(sourceWallet.name)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formatPhp(sourceWallet.balance))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Section("Amount") {
                    TextField("Transfer amount", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Fee (optional)", text: $fee)
                        .keyboardType(.decimalPad)
                }

                Section("Transfer To") {
                    if destinationWallets.isEmpty {
                        Text("No other wallets available")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Destination", selection: $selectedDestId) {
                            Text("Select Wallet").tag("")
                            ForEach(destinationWallets) { wallet in
                                HStack {
                                    Text(wallet.name)
                                    Text("(\(formatPhp(wallet.balance)))")
                                }
                                .tag(wallet.id ?? "")
                            }
                        }
                    }
                }

                if transferAmount > 0 {
                    Section("Summary") {
                        HStack {
                            Text("\(sourceWallet.name) deduction")
                            Spacer()
                            Text(formatPhp(totalDeduction))
                                .monospacedDigit()
                                .foregroundStyle(AppTheme.negative)
                        }
                        HStack {
                            let destName = destinationWallets.first(where: { $0.id == selectedDestId })?.name ?? "Destination"
                            Text("\(destName) received")
                            Spacer()
                            Text(formatPhp(transferAmount))
                                .monospacedDigit()
                                .foregroundStyle(AppTheme.positive)
                        }
                        if feeAmount > 0 {
                            HStack {
                                Text("Transfer fee")
                                Spacer()
                                Text(formatPhp(feeAmount))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Transfer Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        submit()
                    }
                    .disabled(transferAmount <= 0 || selectedDestId.isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func submit() {
        guard transferAmount > 0 else { return }
        guard totalDeduction <= sourceWallet.balance else {
            errorMessage = "Insufficient balance. Available: \(formatPhp(sourceWallet.balance))"
            return
        }
        guard !selectedDestId.isEmpty else {
            errorMessage = "Select a destination wallet."
            return
        }

        isSaving = true
        errorMessage = nil
        Task {
            await onSubmit(transferAmount, feeAmount, selectedDestId)
            dismiss()
        }
    }
}
