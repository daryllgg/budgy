import SwiftUI

struct FinanceView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(ToastManager.self) private var toast
    @Environment(NavigationManager.self) private var nav
    @State private var walletVM = WalletViewModel()
    @State private var depositVM = DepositViewModel()
    @State private var expenseVM = ExpenseViewModel()
    @State private var showAddWallet = false
    @State private var showAddExpense = false
    @State private var editingWallet: Wallet?
    @State private var editingExpense: Expense?
    @State private var depositWallet: Wallet?
    @State private var withdrawWallet: Wallet?
    @State private var deleteWalletTarget: Wallet?
    @State private var deleteExpenseTarget: Expense?
    @State private var selectedExpense: Expense?

    // Expense filters
    @State private var expenseSortBy: ExpenseSortOption = .dateNewest
    @State private var expenseFilterCategory: ExpenseCategory?
    @State private var expenseFilterPeriod: ExpenseFilterPeriod = .all

    var body: some View {
        @Bindable var nav = nav
        NavigationStack {
            VStack(spacing: 0) {
                NetworkStatusLabel()
                    .padding(.horizontal)

                Picker("View", selection: $nav.financeSegment) {
                    Text("Wallets").tag(0)
                    Text("Expenses").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)

                if nav.financeSegment == 0 {
                    walletsContent
                } else {
                    expensesContent
                }
            }
            .navigationTitle(nav.financeSegment == 0 ? "Wallets" : "Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        if nav.financeSegment == 1 {
                            Menu {
                                Section("Sort By") {
                                    ForEach(ExpenseSortOption.allCases, id: \.self) { option in
                                        Button {
                                            expenseSortBy = option
                                        } label: {
                                            Label(option.label, systemImage: expenseSortBy == option ? "checkmark" : "")
                                        }
                                    }
                                }
                                Section("Period") {
                                    ForEach(ExpenseFilterPeriod.allCases, id: \.self) { period in
                                        Button {
                                            expenseFilterPeriod = period
                                        } label: {
                                            Label(period.label, systemImage: expenseFilterPeriod == period ? "checkmark" : "")
                                        }
                                    }
                                }
                                Section("Category") {
                                    Button {
                                        expenseFilterCategory = nil
                                    } label: {
                                        Label("All Categories", systemImage: expenseFilterCategory == nil ? "checkmark" : "")
                                    }
                                    ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                                        Button {
                                            expenseFilterCategory = cat
                                        } label: {
                                            Label(cat.label, systemImage: expenseFilterCategory == cat ? "checkmark" : cat.icon)
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: hasActiveExpenseFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            }
                        }
                        Button {
                            if nav.financeSegment == 0 {
                                showAddWallet = true
                            } else {
                                showAddExpense = true
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            // Wallet sheets
            .sheet(isPresented: $showAddWallet) {
                WalletFormSheet { wallet in
                    guard let uid = authVM.uid else { return }
                    let docId = await walletVM.add(uid: uid, wallet: wallet)
                    if let docId {
                        hapticSuccess()
                        toast.show("Wallet added") {
                            await walletVM.delete(uid: uid, walletId: docId)
                        }
                    }
                }
            }
            .sheet(item: $editingWallet) { wallet in
                WalletFormSheet(wallet: wallet) { updated in
                    guard let uid = authVM.uid, let id = wallet.id else { return }
                    await walletVM.update(uid: uid, walletId: id, data: [
                        "name": updated.name,
                        "type": updated.type.rawValue,
                        "bankName": updated.bankName,
                        "balance": updated.balance,
                        "notes": updated.notes,
                    ])
                    hapticSuccess()
                    toast.show("Wallet updated")
                }
            }
            .sheet(item: $depositWallet) { wallet in
                DepositFormSheet(wallet: wallet) { deposit in
                    guard let uid = authVM.uid else { return }
                    let docId = await depositVM.add(uid: uid, deposit: deposit)
                    if let docId {
                        hapticSuccess()
                        toast.show("Deposit added") {
                            await depositVM.delete(uid: uid, depositId: docId, walletId: deposit.walletId, amount: deposit.amount)
                        }
                    }
                }
            }
            .sheet(item: $withdrawWallet) { wallet in
                TransferFormSheet(sourceWallet: wallet, allWallets: walletVM.wallets) { amount, fee, destWalletId in
                    guard let uid = authVM.uid, let sourceId = wallet.id else { return }
                    await walletVM.transfer(uid: uid, sourceWalletId: sourceId, destWalletId: destWalletId, amount: amount, fee: fee, sourceName: wallet.name)
                    hapticSuccess()
                    toast.show("Transfer completed")
                }
            }
            // Expense sheets
            .sheet(isPresented: $showAddExpense) {
                ExpenseFormSheet(wallets: walletVM.wallets) { expense in
                    guard let uid = authVM.uid else { return }
                    let docId = await expenseVM.add(uid: uid, expense: expense)
                    if let docId {
                        hapticSuccess()
                        toast.show("Expense added") {
                            await expenseVM.delete(uid: uid, expenseId: docId, sourceId: expense.sourceId, amount: expense.amount)
                        }
                    }
                }
            }
            .sheet(item: $editingExpense) { expense in
                ExpenseFormSheet(wallets: walletVM.wallets, expense: expense) { updated in
                    guard let uid = authVM.uid, let id = expense.id else { return }
                    await expenseVM.update(uid: uid, expenseId: id, oldAmount: expense.amount, oldSourceId: expense.sourceId, expense: updated)
                    hapticSuccess()
                    toast.show("Expense updated")
                }
            }
            // Delete confirmations
            .alert("Delete Wallet?", isPresented: Binding(get: { deleteWalletTarget != nil }, set: { if !$0 { deleteWalletTarget = nil } }), presenting: deleteWalletTarget) { wallet in
                Button("Delete", role: .destructive) {
                    guard let uid = authVM.uid, let id = wallet.id else { return }
                    Task {
                        await walletVM.delete(uid: uid, walletId: id)
                        hapticSuccess()
                        toast.show("Wallet deleted")
                    }
                }
            } message: { wallet in
                Text("This will permanently delete \"\(wallet.name)\". This action cannot be undone.")
            }
            .alert("Delete Expense?", isPresented: Binding(get: { deleteExpenseTarget != nil }, set: { if !$0 { deleteExpenseTarget = nil } }), presenting: deleteExpenseTarget) { expense in
                Button("Delete", role: .destructive) {
                    guard let uid = authVM.uid, let id = expense.id else { return }
                    Task {
                        await expenseVM.delete(uid: uid, expenseId: id, sourceId: expense.sourceId, amount: expense.amount)
                        hapticSuccess()
                        toast.show("Expense deleted")
                    }
                }
            } message: { expense in
                Text("This will permanently delete this \(formatPhp(expense.amount)) expense.")
            }
            .refreshable {
                guard let uid = authVM.uid else { return }
                walletVM.subscribe(uid: uid)
                expenseVM.subscribe(uid: uid)
            }
            .onAppear {
                guard let uid = authVM.uid else { return }
                walletVM.subscribe(uid: uid)
                expenseVM.subscribe(uid: uid)
            }
            .onDisappear {
                expenseVM.unsubscribe()
            }
            .onChange(of: nav.showQuickAddExpense) { _, show in
                if show {
                    nav.showQuickAddExpense = false
                    showAddExpense = true
                }
            }
        }
    }

    // MARK: - Expense Filtering

    private var hasActiveExpenseFilters: Bool {
        expenseFilterCategory != nil || expenseFilterPeriod != .all || expenseSortBy != .dateNewest
    }

    private var filteredExpenses: [Expense] {
        var result = expenseVM.expenses

        // Filter by category
        if let cat = expenseFilterCategory {
            result = result.filter { $0.category == cat }
        }

        // Filter by period
        let calendar = Calendar.current
        switch expenseFilterPeriod {
        case .all: break
        case .today:
            result = result.filter { calendar.isDateInToday($0.date) }
        case .thisWeek:
            if let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) {
                result = result.filter { $0.date >= interval.start && $0.date < interval.end }
            }
        case .thisMonth:
            if let interval = calendar.dateInterval(of: .month, for: Date()) {
                result = result.filter { $0.date >= interval.start && $0.date < interval.end }
            }
        }

        // Sort
        switch expenseSortBy {
        case .dateNewest: result.sort { $0.date > $1.date }
        case .dateOldest: result.sort { $0.date < $1.date }
        case .amountHigh: result.sort { $0.amount > $1.amount }
        case .amountLow: result.sort { $0.amount < $1.amount }
        }

        return result
    }

    private var expensesGroupedByDate: [(date: String, expenses: [Expense])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key.formattedMMMddyyyy(), expenses: $0.value) }
    }

    // MARK: - Wallets Content

    @ViewBuilder
    private var walletsContent: some View {
        if walletVM.isLoading {
            ProgressView()
                .frame(maxHeight: .infinity)
        } else if walletVM.wallets.isEmpty {
            EmptyStateView(icon: "creditcard", title: "No Wallets", message: "Add your first wallet to start tracking")
        } else {
            List {
                if !walletVM.bankWallets.isEmpty {
                    Section("Bank Accounts") {
                        ForEach(walletVM.bankWallets) { wallet in
                            NavigationLink(destination: WalletTransactionHistoryView(wallet: wallet)) {
                                WalletRow(wallet: wallet)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { deleteWalletTarget = wallet } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                                Button { editingWallet = wallet } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .leading) {
                                Button { withdrawWallet = wallet } label: {
                                    Label("Transfer", systemImage: "arrow.left.arrow.right")
                                }
                                .tint(.blue)
                                Button { depositWallet = wallet } label: {
                                    Label("Deposit", systemImage: "plus.circle")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }

                if !walletVM.cashWallets.isEmpty {
                    Section("Cash") {
                        ForEach(walletVM.cashWallets) { wallet in
                            NavigationLink(destination: WalletTransactionHistoryView(wallet: wallet)) {
                                WalletRow(wallet: wallet)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { deleteWalletTarget = wallet } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                                Button { editingWallet = wallet } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .leading) {
                                Button { withdrawWallet = wallet } label: {
                                    Label("Transfer", systemImage: "arrow.left.arrow.right")
                                }
                                .tint(.blue)
                                Button { depositWallet = wallet } label: {
                                    Label("Deposit", systemImage: "plus.circle")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Total Balance")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formatPhp(walletVM.totalBalance))
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Expenses Content

    @ViewBuilder
    private var expensesContent: some View {
        if expenseVM.isLoading {
            ProgressView()
                .frame(maxHeight: .infinity)
        } else if expenseVM.expenses.isEmpty {
            EmptyStateView(icon: "receipt", title: "No Expenses", message: "Add your first expense to start tracking")
        } else {
            List {
                Section {
                    ExpenseSummaryCard(expenses: expenseVM.expenses)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

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

                ForEach(expensesGroupedByDate, id: \.date) { group in
                    Section(group.date) {
                        ForEach(group.expenses) { expense in
                            ExpenseRow(expense: expense)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedExpense = expense }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { deleteExpenseTarget = expense } label: {
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
            .scrollContentBackground(.hidden)
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailSheet(expense: expense)
            }
        }
    }
}

// MARK: - Expense Filter/Sort Enums

enum ExpenseSortOption: CaseIterable {
    case dateNewest, dateOldest, amountHigh, amountLow

    var label: String {
        switch self {
        case .dateNewest: "Date (Newest)"
        case .dateOldest: "Date (Oldest)"
        case .amountHigh: "Amount (High → Low)"
        case .amountLow: "Amount (Low → High)"
        }
    }
}

enum ExpenseFilterPeriod: CaseIterable {
    case all, today, thisWeek, thisMonth

    var label: String {
        switch self {
        case .all: "All Time"
        case .today: "Today"
        case .thisWeek: "This Week"
        case .thisMonth: "This Month"
        }
    }
}
