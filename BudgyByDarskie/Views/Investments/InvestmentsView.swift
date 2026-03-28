import SwiftUI

struct InvestmentsView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(ToastManager.self) private var toast
    @State private var investmentVM = InvestmentViewModel()
    @State private var walletVM = WalletViewModel()
    @State private var stockVM = StockPriceViewModel()
    @State private var exchangeVM = ExchangeRateViewModel()
    @State private var showAddInvestment = false
    @State private var editingInvestment: Investment?
    @State private var deleteTarget: Investment?
    @State private var tpslTarget: Investment?

    // Filters
    @State private var selectedTab: InvestmentTab = .all
    @State private var sortBy: InvestmentSortOption = .dateNewest

    private var filteredInvestments: [Investment] {
        var result = investmentVM.investments

        if let type = selectedTab.investmentType {
            result = result.filter { $0.investmentType == type }
        }

        switch sortBy {
        case .dateNewest: result.sort { $0.date > $1.date }
        case .dateOldest: result.sort { $0.date < $1.date }
        case .amountHigh: result.sort { $0.amountPhp > $1.amountPhp }
        case .amountLow: result.sort { $0.amountPhp < $1.amountPhp }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if investmentVM.isLoading {
                    ProgressView()
                } else {
                    VStack(spacing: 0) {
                        Picker("Type", selection: $selectedTab) {
                            ForEach(InvestmentTab.allCases, id: \.self) { tab in
                                Text(tab.label).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top)

                        ScrollView {
                            VStack(spacing: 16) {
                                NetworkStatusLabel()

                                PortfolioSummaryCards(
                                    selectedTab: selectedTab,
                                    portfolio: investmentVM.portfolio,
                                    investments: filteredInvestments,
                                    vooPrice: stockVM.vooPrice,
                                    vooChange: stockVM.vooChange,
                                    vooChangePercent: stockVM.vooChangePercent,
                                    exchangeRate: exchangeVM.usdToPhp
                                )

                                if filteredInvestments.isEmpty {
                                    EmptyStateView(icon: "chart.line.uptrend.xyaxis", title: "No \(selectedTab.label) Investments", message: "Add your first investment")
                                } else {
                                    LazyVStack(spacing: 8) {
                                        ForEach(filteredInvestments) { inv in
                                            InvestmentRow(investment: inv)
                                                .opacity(inv.exited == true ? 0.5 : 1.0)
                                                .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 20))
                                                .contextMenu {
                                                    if inv.exited != true {
                                                        Button { tpslTarget = inv } label: {
                                                            Label("TP / SL", systemImage: "arrow.uturn.down.circle")
                                                        }
                                                        Button { editingInvestment = inv } label: {
                                                            Label("Edit", systemImage: "pencil")
                                                        }
                                                    }
                                                    Button(role: .destructive) { deleteTarget = inv } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                    .tint(.red)
                                                }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Investments")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        WatchlistView()
                    } label: {
                        Image(systemName: "star.circle")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(InvestmentSortOption.allCases, id: \.self) { option in
                                Button {
                                    sortBy = option
                                } label: {
                                    Label(option.label, systemImage: sortBy == option ? "checkmark" : "")
                                }
                            }
                        } label: {
                            Image(systemName: sortBy != .dateNewest ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        }
                        Button { showAddInvestment = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddInvestment) {
                InvestmentFormSheet(wallets: walletVM.wallets) { inv in
                    guard let uid = authVM.uid else { return }
                    let docId = await investmentVM.add(uid: uid, investment: inv)
                    if let docId {
                        hapticSuccess()
                        toast.show("Investment added") {
                            await investmentVM.delete(uid: uid, investmentId: docId, sourceId: inv.sourceId, amountPhp: inv.amountPhp)
                        }
                    }
                }
            }
            .sheet(item: $editingInvestment) { inv in
                InvestmentFormSheet(wallets: walletVM.wallets, investment: inv) { updated in
                    guard let uid = authVM.uid, let id = inv.id else { return }
                    await investmentVM.update(uid: uid, investmentId: id, oldAmountPhp: inv.amountPhp, oldSourceId: inv.sourceId, investment: updated)
                    hapticSuccess()
                    toast.show("Investment updated")
                }
            }
            .sheet(item: $tpslTarget) { inv in
                TPSLFormSheet(investment: inv, wallets: walletVM.wallets) { exit in
                    guard let uid = authVM.uid else { return }
                    investmentVM.tpsl(uid: uid, exit: exit)
                    hapticSuccess()
                    toast.show(exit.profit >= 0 ? "TP recorded" : "SL recorded")
                }
            }
            .alert("Delete Investment?", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }), presenting: deleteTarget) { inv in
                Button("Delete", role: .destructive) {
                    guard let uid = authVM.uid, let id = inv.id else { return }
                    Task {
                        await investmentVM.delete(uid: uid, investmentId: id, sourceId: inv.sourceId, amountPhp: inv.amountPhp)
                        hapticSuccess()
                        toast.show("Investment deleted")
                    }
                }
            } message: { inv in
                Text("This will permanently delete this \(formatPhp(inv.amountPhp)) investment.")
            }
            .refreshable {
                guard let uid = authVM.uid else { return }
                investmentVM.subscribe(uid: uid, year: nil)
                investmentVM.subscribeAll(uid: uid)
                walletVM.subscribe(uid: uid)
                await stockVM.fetchVOOPrice()
                await exchangeVM.fetchRate()
            }
            .onAppear {
                guard let uid = authVM.uid else { return }
                investmentVM.subscribe(uid: uid, year: nil)
                investmentVM.subscribeAll(uid: uid)
                walletVM.subscribe(uid: uid)
                Task {
                    await stockVM.fetchVOOPrice()
                    await exchangeVM.fetchRate()
                }
            }
            .onDisappear {
                investmentVM.unsubscribe()
                walletVM.unsubscribe()
            }
        }
    }
}

enum InvestmentTab: CaseIterable {
    case all, crypto, stock, other

    var label: String {
        switch self {
        case .all: "All"
        case .crypto: "Crypto"
        case .stock: "Stock"
        case .other: "Other"
        }
    }

    var investmentType: InvestmentType? {
        switch self {
        case .all: nil
        case .crypto: .crypto
        case .stock: .stock
        case .other: .other
        }
    }
}

enum InvestmentSortOption: CaseIterable {
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
