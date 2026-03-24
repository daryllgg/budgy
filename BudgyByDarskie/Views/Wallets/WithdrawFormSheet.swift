import SwiftUI

struct WithdrawFormSheet: View {
    let bankWallet: Wallet
    let cashWallets: [Wallet]
    let onSubmit: (Double, Double, String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var fee = ""
    @State private var selectedCashId = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var withdrawAmount: Double { Double(amount) ?? 0 }
    private var feeAmount: Double { Double(fee) ?? 0 }
    private var totalDeduction: Double { withdrawAmount + feeAmount }

    var body: some View {
        NavigationStack {
            Form {
                Section("Withdraw From") {
                    HStack {
                        Image(systemName: "building.columns.fill")
                            .foregroundStyle(AppTheme.wallets)
                        Text(bankWallet.name)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formatPhp(bankWallet.balance))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Section("Amount") {
                    TextField("Withdrawal amount", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Fee (optional)", text: $fee)
                        .keyboardType(.decimalPad)
                }

                if cashWallets.count > 1 {
                    Section("Receive To") {
                        Picker("Cash Wallet", selection: $selectedCashId) {
                            ForEach(cashWallets) { wallet in
                                Text(wallet.name).tag(wallet.id ?? "")
                            }
                        }
                    }
                } else if let cash = cashWallets.first {
                    Section("Receive To") {
                        HStack {
                            Image(systemName: "banknote.fill")
                                .foregroundStyle(AppTheme.positive)
                            Text(cash.name)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatPhp(cash.balance))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                if withdrawAmount > 0 {
                    Section("Summary") {
                        HStack {
                            Text("Bank deduction")
                            Spacer()
                            Text(formatPhp(totalDeduction))
                                .monospacedDigit()
                                .foregroundStyle(AppTheme.negative)
                        }
                        HStack {
                            Text("Cash received")
                            Spacer()
                            Text(formatPhp(withdrawAmount))
                                .monospacedDigit()
                                .foregroundStyle(AppTheme.positive)
                        }
                        if feeAmount > 0 {
                            HStack {
                                Text("Transaction fee")
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

                if withdrawAmount <= 0 || selectedCashId.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            if withdrawAmount <= 0 {
                                Label("Enter a withdrawal amount", systemImage: "exclamationmark.circle")
                            }
                            if selectedCashId.isEmpty {
                                Label("No cash wallet available", systemImage: "exclamationmark.circle")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Withdraw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        submit()
                    }
                    .disabled(withdrawAmount <= 0 || selectedCashId.isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let first = cashWallets.first?.id {
                    selectedCashId = first
                }
            }
        }
    }

    private func submit() {
        guard withdrawAmount > 0 else { return }
        guard totalDeduction <= bankWallet.balance else {
            errorMessage = "Insufficient balance. Available: \(formatPhp(bankWallet.balance))"
            return
        }
        guard !selectedCashId.isEmpty else {
            errorMessage = "No cash wallet available to receive funds."
            return
        }

        isSaving = true
        errorMessage = nil
        Task {
            await onSubmit(withdrawAmount, feeAmount, selectedCashId)
            dismiss()
        }
    }
}
