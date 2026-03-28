import SwiftUI

struct BuySellView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(ToastManager.self) private var toast
    @State private var buySellVM = BuySellViewModel()
    @State private var walletVM = WalletViewModel()
    @State private var profitVM = ProfitAllocationViewModel()
    @State private var showAddTx = false
    @State private var editingTx: BuySellTransaction?
    @State private var deleteTarget: BuySellTransaction?
    @State private var showAllocations = false
    @State private var sellingTx: BuySellTransaction?

    // Filters
    @State private var sortBy: BuySellSortOption = .dateNewest
    @State private var filterStatus: BuySellStatus?
    @State private var filterType: ItemType?

    private var hasActiveFilters: Bool {
        filterStatus != nil || filterType != nil || sortBy != .dateNewest
    }

    private var filteredTransactions: [BuySellTransaction] {
        var result = buySellVM.transactions

        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        if let type = filterType {
            result = result.filter { $0.itemType == type }
        }

        switch sortBy {
        case .dateNewest: result.sort { $0.order > $1.order }
        case .dateOldest: result.sort { $0.order < $1.order }
        case .profitHigh: result.sort { ($0.profit ?? 0) > ($1.profit ?? 0) }
        case .profitLow: result.sort { ($0.profit ?? 0) < ($1.profit ?? 0) }
        }

        return result
    }

    var body: some View {
        Group {
            if buySellVM.isLoading {
                ProgressView()
            } else {
                List {
                    Section("Profit Summary") {
                        HStack {
                            Text("Total Profit")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatPhp(buySellVM.totalProfit))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(.green)
                        }
                        HStack(spacing: 16) {
                            Label("\(buySellVM.soldCount) Sold", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Label("\(buySellVM.pendingCount) Pending", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Label("\(buySellVM.availableCount) Available", systemImage: "tag")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }

                        Button { showAllocations = true } label: {
                            Label("Profit Allocations", systemImage: "chart.pie")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.glass)
                    }

                    if buySellVM.transactions.isEmpty {
                        Section {
                            EmptyStateView(icon: "arrow.left.arrow.right", title: "No Transactions", message: "Add your first buy & sell transaction")
                        }
                    } else {
                        Section("Transactions") {
                            ForEach(filteredTransactions) { tx in
                                transactionRow(tx)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Buy & Sell")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Menu {
                        Section("Sort By") {
                            ForEach(BuySellSortOption.allCases, id: \.self) { option in
                                Button {
                                    sortBy = option
                                } label: {
                                    Label(option.label, systemImage: sortBy == option ? "checkmark" : "")
                                }
                            }
                        }
                        Section("Status") {
                            Button {
                                filterStatus = nil
                            } label: {
                                Label("All Statuses", systemImage: filterStatus == nil ? "checkmark" : "")
                            }
                            ForEach(BuySellStatus.allCases, id: \.self) { status in
                                Button {
                                    filterStatus = status
                                } label: {
                                    Label(status.label, systemImage: filterStatus == status ? "checkmark" : "")
                                }
                            }
                        }
                        Section("Item Type") {
                            Button {
                                filterType = nil
                            } label: {
                                Label("All Types", systemImage: filterType == nil ? "checkmark" : "")
                            }
                            ForEach(ItemType.allCases, id: \.self) { type in
                                Button {
                                    filterType = type
                                } label: {
                                    Label(type.label, systemImage: filterType == type ? "checkmark" : "")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    Button { showAddTx = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTx) {
            BuySellFormSheet(wallets: walletVM.wallets) { tx in
                guard let uid = authVM.uid else { return }
                let docId = await buySellVM.add(uid: uid, tx: tx)
                if docId != nil {
                    hapticSuccess()
                    toast.show("Added (\(tx.fundingSources.count) source\(tx.fundingSources.count == 1 ? "" : "s") deducted)")
                } else {
                    toast.show("Failed: \(buySellVM.errorMessage ?? "Unknown error")")
                }
            }
        }
        .sheet(item: $editingTx) { tx in
            BuySellFormSheet(wallets: walletVM.wallets, transaction: tx) { updated in
                guard let uid = authVM.uid, let id = tx.id else { return }
                await buySellVM.update(uid: uid, txId: id, oldFundingSources: tx.fundingSources, tx: updated)
                hapticSuccess()
                toast.show("Transaction updated")
            }
        }
        .sheet(item: $sellingTx) { tx in
            SoldFormSheet(transaction: tx, wallets: walletVM.wallets) { sellPrice, buyerName, dateSold, destinations in
                guard let uid = authVM.uid, let id = tx.id else { return }
                buySellVM.markAsSold(uid: uid, txId: id, buyPrice: tx.buyPrice, sellPrice: sellPrice, buyerName: buyerName, dateSold: dateSold, soldDestinations: destinations)
                hapticSuccess()
                toast.show("Marked as sold")
            }
        }
        .sheet(isPresented: $showAllocations) {
            ProfitAllocationSheet(profitVM: profitVM, totalProfit: buySellVM.totalProfit)
        }
        .alert("Delete Transaction?", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }), presenting: deleteTarget) { tx in
            Button("Delete", role: .destructive) {
                guard let uid = authVM.uid, let id = tx.id else { return }
                Task {
                    await buySellVM.delete(uid: uid, txId: id, fundingSources: tx.fundingSources)
                    hapticSuccess()
                    toast.show("Transaction deleted")
                }
            }
        } message: { tx in
            Text("This will permanently delete \"\(tx.itemName)\" and restore wallet balances.")
        }
        .refreshable {
            guard let uid = authVM.uid else { return }
            buySellVM.subscribe(uid: uid)
            walletVM.subscribe(uid: uid)
            profitVM.subscribe(uid: uid)
        }
        .onAppear {
            guard let uid = authVM.uid else { return }
            buySellVM.subscribe(uid: uid)
            walletVM.subscribe(uid: uid)
            profitVM.subscribe(uid: uid)
        }
        .onDisappear {
            buySellVM.unsubscribe()
            walletVM.unsubscribe()
            profitVM.unsubscribe()
        }
    }

    @ViewBuilder
    private func transactionRow(_ tx: BuySellTransaction) -> some View {
        NavigationLink {
            BuySellDetailView(transaction: tx)
        } label: {
            BuySellRow(transaction: tx)
        }
        .swipeActions(edge: .trailing) {
            if tx.status != .sold {
                Button(role: .destructive) { deleteTarget = tx } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
                Button { editingTx = tx } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .leading) {
            if tx.status == .available {
                Button { sellingTx = tx } label: {
                    Label("Sold", systemImage: "banknote")
                }
                .tint(.green)
            }
        }
    }
}

enum BuySellSortOption: CaseIterable {
    case dateNewest, dateOldest, profitHigh, profitLow

    var label: String {
        switch self {
        case .dateNewest: "Date (Newest)"
        case .dateOldest: "Date (Oldest)"
        case .profitHigh: "Profit (High → Low)"
        case .profitLow: "Profit (Low → High)"
        }
    }
}
