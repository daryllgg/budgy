import SwiftUI
import FirebaseFirestore

struct PaymentHistoryView: View {
    let receivable: Receivable
    let wallets: [Wallet]

    @Environment(ToastManager.self) private var toast
    @State private var payments: [ReceivablePayment] = []
    @State private var listener: ListenerRegistration?
    @State private var showAddPayment = false
    @State private var deleteTarget: ReceivablePayment?

    private var totalPaid: Double { payments.reduce(0) { $0 + $1.amount } }
    private var remaining: Double { receivable.amount - totalPaid }

    var body: some View {
        List {
            Section("Summary") {
                if let createdAt = receivable.createdAt {
                    HStack {
                        Text("Date Added")
                        Spacer()
                        Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Text("Total Amount")
                    Spacer()
                    Text(formatPhp(receivable.amount)).monospacedDigit()
                }
                HStack {
                    Text("Total Paid")
                    Spacer()
                    Text(formatPhp(totalPaid)).monospacedDigit().foregroundStyle(.green)
                }
                HStack {
                    Text("Remaining")
                    Spacer()
                    Text(formatPhp(remaining))
                        .monospacedDigit()
                        .foregroundStyle(remaining > 0 ? .orange : .green)
                }
            }

            Section("Payments") {
                if payments.isEmpty {
                    Text("No payments yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(payments) { payment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(formatPhp(payment.amount))
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                Spacer()
                                Text(payment.date.formattedMMMddyyyy())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(payment.destinations) { dest in
                                Text("→ \(dest.walletName): \(formatPhp(dest.amount))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) { deleteTarget = payment } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle(receivable.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddPayment = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddPayment) {
            PaymentFormSheet(wallets: wallets, maxAmount: remaining) { payment in
                guard let uid = AuthService.shared.uid, let recId = receivable.id else { return }
                try await ReceivablePaymentService.add(uid: uid, receivableId: recId, payment: payment)
                hapticSuccess()
                toast.show("Payment added")
            }
        }
        .alert("Delete Payment?", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }), presenting: deleteTarget) { payment in
            Button("Delete", role: .destructive) {
                guard let uid = AuthService.shared.uid, let recId = receivable.id else { return }
                Task {
                    try? await ReceivablePaymentService.delete(uid: uid, receivableId: recId, payment: payment)
                    hapticSuccess()
                    toast.show("Payment deleted")
                }
            }
        } message: { payment in
            Text("This will permanently delete this \(formatPhp(payment.amount)) payment.")
        }
        .onAppear {
            guard let uid = AuthService.shared.uid, let recId = receivable.id else { return }
            let reg = ReceivablePaymentService.subscribe(uid: uid, receivableId: recId) { p in
                payments = p
            }
            listener = reg
        }
        .onDisappear {
            listener?.remove()
        }
    }
}

struct PaymentFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let wallets: [Wallet]
    let maxAmount: Double
    let onSave: (ReceivablePayment) async throws -> Void

    @State private var amount = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var destinations: [PaymentDestination] = []
    @State private var newWalletId = ""
    @State private var newWalletAmount = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                DatePicker("Date", selection: $date, displayedComponents: .date)

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
                }

                TextField("Notes", text: $notes)
            }
            .navigationTitle("Add Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            var finalDestinations = destinations
                            if !newWalletId.isEmpty, let amt = Double(newWalletAmount), amt > 0 {
                                let name = wallets.first(where: { $0.id == newWalletId })?.name ?? ""
                                finalDestinations.append(PaymentDestination(walletId: newWalletId, walletName: name, amount: amt))
                            }
                            let payment = ReceivablePayment(
                                amount: Double(amount) ?? 0,
                                date: date,
                                destinations: finalDestinations,
                                notes: notes
                            )
                            try? await onSave(payment)
                            dismiss()
                        }
                    }
                    .disabled(amount.isEmpty || (destinations.isEmpty && (newWalletId.isEmpty || newWalletAmount.isEmpty)) || isSaving)
                }
            }
        }
        .onChange(of: newWalletId) { _, newId in
            if !newId.isEmpty && newWalletAmount.isEmpty && destinations.isEmpty {
                newWalletAmount = amount
            }
        }
        .presentationDetents([.medium, .large])
    }
}
