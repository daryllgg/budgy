import SwiftUI

struct ExpensesView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var expenseVM = ExpenseViewModel()
    @State private var walletVM = WalletViewModel()
    @State private var showAddExpense = false
    @State private var showScanner = false
    @State private var scannedResult: ReceiptScanResult?
    @State private var editingExpense: Expense?
    @State private var deleteTarget: Expense?

    var body: some View {
        NavigationStack {
            Group {
                if expenseVM.isLoading {
                    ProgressView()
                } else if expenseVM.expenses.isEmpty {
                    EmptyStateView(icon: "receipt", title: "No Expenses", message: "Add your first expense to start tracking")
                } else {
                    List {
                        // Category summary
                        Section("By Category") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(expenseVM.byCategory.sorted(by: { $0.value > $1.value })), id: \.key) { cat, amount in
                                        VStack(spacing: 4) {
                                            Image(systemName: cat.icon)
                                                .foregroundStyle(cat.color)
                                            Text(formatPhp(amount))
                                                .font(.caption.bold())
                                                .monospacedDigit()
                                            Text(cat.label)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .glassEffect(.regular, in: .rect(cornerRadius: 10))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        Section("Total: \(formatPhp(expenseVM.totalExpenses))") {
                            ForEach(expenseVM.expenses) { expense in
                                ExpenseRow(expense: expense)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) { deleteTarget = expense } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                        Button { editingExpense = expense } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.orange)
                                    }
                            }
                        }

                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 16) {
                        Button { showAddExpense = true } label: {
                            Image(systemName: "plus")
                        }
                        Button { showScanner = true } label: {
                            Image(systemName: "doc.text.viewfinder")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddExpense, onDismiss: { scannedResult = nil }) {
                ExpenseFormSheet(wallets: walletVM.wallets, scanResult: scannedResult) { expense in
                    guard let uid = authVM.uid else { return }
                    _ = await expenseVM.add(uid: uid, expense: expense)
                }
            }
            .sheet(item: $editingExpense) { expense in
                ExpenseFormSheet(wallets: walletVM.wallets, expense: expense) { updated in
                    guard let uid = authVM.uid, let id = expense.id else { return }
                    await expenseVM.update(uid: uid, expenseId: id, oldAmount: expense.amount, oldSourceId: expense.sourceId, expense: updated)
                }
            }
            .sheet(isPresented: $showScanner) {
                ReceiptScannerView { result in
                    scannedResult = result
                    showScanner = false
                    showAddExpense = true
                }
            }
            .alert("Delete Expense?", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }), presenting: deleteTarget) { expense in
                Button("Delete", role: .destructive) {
                    guard let uid = authVM.uid, let id = expense.id else { return }
                    Task { await expenseVM.delete(uid: uid, expenseId: id, sourceId: expense.sourceId, amount: expense.amount) }
                }
            } message: { expense in
                Text("This will permanently delete this \(formatPhp(expense.amount)) expense.")
            }
            .onAppear {
                guard let uid = authVM.uid else { return }
                expenseVM.subscribe(uid: uid)
                walletVM.subscribe(uid: uid)
            }
            .onDisappear {
                expenseVM.unsubscribe()
                walletVM.unsubscribe()
            }
        }
    }
}
