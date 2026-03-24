import SwiftUI

struct PersonReceivablesView: View {
    @State var personName: String
    var walletVM: WalletViewModel

    @Environment(AuthViewModel.self) private var authVM
    @Environment(ToastManager.self) private var toast
    @State private var receivableVM = ReceivableViewModel()
    @State private var showAddReceivable = false
    @State private var editingReceivable: Receivable?
    @State private var deleteTarget: Receivable?
    @State private var selectedTab = 0
    @State private var showRenameAlert = false
    @State private var newPersonName = ""

    private var personReceivables: [Receivable] {
        receivableVM.receivables.filter { $0.name == personName }
    }

    private var ongoingReceivables: [Receivable] {
        personReceivables.filter { !$0.isFullyPaid }
    }

    private var completedReceivables: [Receivable] {
        personReceivables.filter { $0.isFullyPaid }
    }

    private var displayedReceivables: [Receivable] {
        selectedTab == 0 ? ongoingReceivables : completedReceivables
    }

    private var totalAmount: Double {
        personReceivables.reduce(0) { $0 + $1.amount }
    }

    private var totalPaid: Double {
        personReceivables.reduce(0) { $0 + ($1.totalPaid ?? 0) }
    }

    private var remaining: Double {
        totalAmount - totalPaid
    }

    private var lastUpdated: Date? {
        personReceivables.compactMap { $0.updatedAt }.max()
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Status", selection: $selectedTab) {
                Text("Ongoing (\(ongoingReceivables.count))").tag(0)
                Text("Completed (\(completedReceivables.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 12)

            List {
                Section {
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(formatPhp(totalAmount)).monospacedDigit()
                    }
                    HStack {
                        Text("Paid")
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
                    if let lastUpdated {
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(lastUpdated.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if displayedReceivables.isEmpty {
                    Section {
                        Text(selectedTab == 0 ? "No ongoing receivables" : "No completed receivables")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ForEach(displayedReceivables) { rec in
                            NavigationLink {
                                PaymentHistoryView(receivable: rec, wallets: walletVM.wallets)
                            } label: {
                                ReceivableRow(receivable: rec, showName: false)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { deleteTarget = rec } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                                Button { editingReceivable = rec } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(personName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button {
                        newPersonName = personName
                        showRenameAlert = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    Button { showAddReceivable = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .alert("Rename Person", isPresented: $showRenameAlert) {
            TextField("Name", text: $newPersonName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                guard let uid = authVM.uid, !newPersonName.isEmpty, newPersonName != personName else { return }
                Task {
                    for rec in personReceivables {
                        guard let id = rec.id else { continue }
                        await receivableVM.update(uid: uid, receivableId: id, data: ["name": newPersonName])
                    }
                    personName = newPersonName
                    hapticSuccess()
                    toast.show("Person renamed")
                }
            }
        } message: {
            Text("Rename \"\(personName)\" across all their receivables.")
        }
        .sheet(isPresented: $showAddReceivable) {
            ReceivableFormSheet(wallets: walletVM.wallets, prefillName: personName) { rec in
                guard let uid = authVM.uid else { return }
                let docId = await receivableVM.add(uid: uid, receivable: rec)
                if let docId {
                    hapticSuccess()
                    toast.show("Receivable added") {
                        await receivableVM.delete(uid: uid, receivableId: docId, sourceId: rec.sourceId, amount: rec.amount)
                    }
                }
            }
        }
        .sheet(item: $editingReceivable) { rec in
            ReceivableFormSheet(wallets: walletVM.wallets, receivable: rec) { updated in
                guard let uid = authVM.uid, let id = rec.id else { return }
                await receivableVM.update(uid: uid, receivableId: id, data: [
                    "name": updated.name,
                    "description": updated.receivableDescription,
                    "amount": updated.amount,
                    "isReimbursement": updated.isReimbursement,
                    "notes": updated.notes,
                ])
                hapticSuccess()
                toast.show("Receivable updated")
            }
        }
        .alert("Delete Receivable?", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }), presenting: deleteTarget) { rec in
            Button("Delete", role: .destructive) {
                guard let uid = authVM.uid, let id = rec.id else { return }
                Task {
                    await receivableVM.delete(uid: uid, receivableId: id, sourceId: rec.sourceId, amount: rec.amount)
                    hapticSuccess()
                    let msg = rec.sourceId.isEmpty ? "Receivable deleted" : "Receivable deleted (funds returned to \(rec.sourceName))"
                    toast.show(msg)
                }
            }
        } message: { rec in
            let fundMsg = rec.sourceId.isEmpty ? "" : "\nFunds of \(formatPhp(rec.amount)) will be returned to \(rec.sourceName)."
            Text("This will permanently delete \"\(rec.receivableDescription)\".\(fundMsg)")
        }
        .onAppear {
            guard let uid = authVM.uid else { return }
            receivableVM.subscribe(uid: uid)
        }
        .onDisappear {
            receivableVM.unsubscribe()
        }
    }
}
