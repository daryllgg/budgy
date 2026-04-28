import SwiftUI

struct BulkPaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let receivables: [Receivable]
    let wallets: [Wallet]
    let onSave: ([PaymentDestination], Date, String) async throws -> Void

    @State private var date = Date()
    @State private var notes = ""
    @State private var destinations: [PaymentDestination] = []
    @State private var newWalletId = ""
    @State private var newWalletAmount = ""
    @State private var isSaving = false

    private var totalAmount: Double {
        receivables.reduce(0) { $0 + $1.remaining }
    }

    private var destinationsTotal: Double {
        var total = destinations.reduce(0) { $0 + $1.amount }
        if let pending = pendingDestinationAmount {
            total += pending
        }
        return total
    }

    private var pendingDestinationAmount: Double? {
        guard !newWalletId.isEmpty, let amt = Double(newWalletAmount), amt > 0 else { return nil }
        return amt
    }

    private var remainingToAllocate: Double {
        totalAmount - destinationsTotal
    }

    private var canSave: Bool {
        !isSaving && (!destinations.isEmpty || pendingDestinationAmount != nil)
    }

    private var allDestinations: [PaymentDestination] {
        var result = destinations
        if !newWalletId.isEmpty, let amt = Double(newWalletAmount), amt > 0 {
            let name = wallets.first(where: { $0.id == newWalletId })?.name ?? ""
            result.append(PaymentDestination(walletId: newWalletId, walletName: name, amount: amt))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Selected Receivables") {
                    ForEach(receivables) { rec in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.receivableDescription.isEmpty ? rec.name : rec.receivableDescription)
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text(formatPhp(rec.remaining))
                                .monospacedDigit()
                                .foregroundStyle(.orange)
                        }
                    }
                    HStack {
                        Text("Total").fontWeight(.semibold)
                        Spacer()
                        Text(formatPhp(totalAmount))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Destination Wallets") {
                    ForEach(destinations) { dest in
                        HStack {
                            Text(dest.walletName)
                            Spacer()
                            Text(formatPhp(dest.amount)).monospacedDigit()
                            Button { destinations.removeAll(where: { $0.walletId == dest.walletId }) } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                            }
                        }
                    }
                    HStack {
                        Picker("Wallet", selection: $newWalletId) {
                            Text("Select").tag("")
                            ForEach(wallets) { w in
                                Text("\(w.name) (\(formatPhp(w.balance)))").tag(w.id ?? "")
                            }
                        }
                        .labelsHidden()
                        TextField("Amount", text: $newWalletAmount)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                        Button {
                            guard let amt = Double(newWalletAmount), !newWalletId.isEmpty else { return }
                            let name = wallets.first(where: { $0.id == newWalletId })?.name ?? ""
                            destinations.append(PaymentDestination(walletId: newWalletId, walletName: name, amount: amt))
                            newWalletId = ""
                            newWalletAmount = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                    if remainingToAllocate > 0.01 {
                        HStack {
                            Text("Remaining to allocate")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatPhp(remainingToAllocate))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.orange)
                        }
                    }
                }

                TextField("Notes", text: $notes)
            }
            .navigationTitle("Bulk Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pay") {
                        isSaving = true
                        Task {
                            try? await onSave(allDestinations, date, notes)
                            dismiss()
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
        }
        .onChange(of: newWalletId) { _, newId in
            if !newId.isEmpty && newWalletAmount.isEmpty && destinations.isEmpty {
                newWalletAmount = String(format: "%.0f", totalAmount)
            }
        }
        .presentationDetents([.medium, .large])
    }
}
