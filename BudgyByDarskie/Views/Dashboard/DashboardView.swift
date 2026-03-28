import SwiftUI
import Charts

struct DashboardView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(AppearanceManager.self) private var appearance
    @Environment(NavigationManager.self) private var nav
    @Environment(ToastManager.self) private var toast
    @State private var walletVM = WalletViewModel()
    @State private var expenseVM = ExpenseViewModel()
    @State private var investmentVM = InvestmentViewModel()
    @State private var buySellVM = BuySellViewModel()
    @State private var assetVM = AssetViewModel()
    @State private var receivableVM = ReceivableViewModel()
    @State private var showBreakdown = false
    @State private var showExpenseForm = false

    private var grandTotal: Double {
        walletVM.totalBalance + investmentVM.totalInvestedPhp + receivableVM.totalReceivables + assetVM.totalAssets + buySellVM.totalInventoryValue
    }

    private var thisWeekExpenses: Double {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        return expenseVM.expenses
            .filter { $0.date >= interval.start && $0.date < interval.end }
            .reduce(0) { $0 + $1.amount }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let firstName = authVM.displayName.components(separatedBy: " ").first ?? ""
        switch hour {
        case 5..<12: return "Good morning, \(firstName)"
        case 12..<17: return "Good afternoon, \(firstName)"
        case 17..<22: return "Good evening, \(firstName)"
        default: return "Good night, \(firstName)"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NetworkStatusLabel()

                    // Greeting
                    Text(greeting)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Grand Total Card
                    Button { showBreakdown = true } label: {
                        GrandTotalCard(total: grandTotal, hidden: appearance.hideValues)
                    }
                    .buttonStyle(.plain)

                    // Stat Cards - Tappable for navigation
                    GlassEffectContainer {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            Button { nav.navigateToWallets() } label: {
                                StatCard(title: "Wallets", value: appearance.maskedValue(formatPhp(walletVM.totalBalance)), icon: "creditcard.fill", color: AppTheme.wallets)
                            }
                            .buttonStyle(.plain)

                            Button { nav.navigateToExpenses() } label: {
                                StatCard(title: "Expenses", value: appearance.maskedValue(formatPhp(thisWeekExpenses)), icon: "list.bullet.rectangle.fill", color: AppTheme.expenses, subtitle: "This Week")
                            }
                            .buttonStyle(.plain)

                            Button { nav.navigateToInvestments() } label: {
                                StatCard(title: "Investments", value: appearance.maskedValue(formatPhp(investmentVM.totalInvestedPhp)), icon: "chart.line.uptrend.xyaxis", color: AppTheme.investments)
                            }
                            .buttonStyle(.plain)

                            Button { nav.navigateToBuySell() } label: {
                                StatCard(title: "B&S Profit", value: appearance.maskedValue(formatPhp(buySellVM.totalProfit)), icon: "arrow.left.arrow.right.circle.fill", color: AppTheme.buySell)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Expense by Category Chart
                    if !expenseVM.byCategory.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Expenses by Category")
                                    .font(.headline)
                                Chart {
                                    ForEach(Array(expenseVM.byCategory.sorted(by: { $0.value > $1.value })), id: \.key) { cat, amount in
                                        SectorMark(angle: .value("Amount", amount), innerRadius: .ratio(0.6))
                                            .foregroundStyle(cat.color)
                                    }
                                }
                                .frame(height: 200)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                                    ForEach(Array(expenseVM.byCategory.sorted(by: { $0.value > $1.value })), id: \.key) { cat, amount in
                                        HStack(spacing: 6) {
                                            Circle().fill(cat.color).frame(width: 8, height: 8)
                                            Text(cat.label)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text(appearance.maskedValue(formatPhp(amount)))
                                                .font(.caption)
                                                .monospacedDigit()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Monthly Expenses Chart
                    if !expenseVM.expenses.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Monthly Expenses")
                                    .font(.headline)
                                Chart {
                                    ForEach(monthlyExpenses, id: \.month) { item in
                                        BarMark(
                                            x: .value("Month", item.month),
                                            y: .value("Amount", item.total)
                                        )
                                        .foregroundStyle(AppTheme.accent.gradient)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                }
                                .frame(height: 200)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.snappy(duration: 0.2)) {
                                appearance.hideValues.toggle()
                            }
                        } label: {
                            Image(systemName: appearance.hideValues ? "eye.slash.fill" : "eye.fill")
                        }
                        Button { showExpenseForm = true } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showBreakdown) {
                GrandTotalBreakdownSheet(
                    walletTotal: walletVM.totalBalance,
                    investmentTotal: investmentVM.totalInvestedPhp,
                    receivableTotal: receivableVM.totalReceivables,
                    assetTotal: assetVM.totalAssets,
                    buySellInventory: buySellVM.totalInventoryValue,
                    grandTotal: grandTotal
                )
            }
            .sheet(isPresented: $showExpenseForm) {
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
            .refreshable { subscribe() }
            .onAppear { subscribe() }
            .onDisappear { unsubscribe() }
        }
    }

    private var monthlyExpenses: [(month: String, total: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expenseVM.expenses) { expense in
            calendar.component(.month, from: expense.date)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return (1...12).compactMap { month in
            let total = grouped[month]?.reduce(0) { $0 + $1.amount } ?? 0
            guard total > 0 else { return nil }
            var comps = DateComponents()
            comps.month = month
            let date = calendar.date(from: comps) ?? Date()
            return (month: formatter.string(from: date), total: total)
        }
    }

    private func subscribe() {
        guard let uid = authVM.uid else { return }
        walletVM.subscribe(uid: uid)
        expenseVM.subscribe(uid: uid)
        investmentVM.subscribe(uid: uid, year: nil)
        buySellVM.subscribe(uid: uid)
        assetVM.subscribe(uid: uid)
        receivableVM.subscribe(uid: uid)
    }

    private func unsubscribe() {
        walletVM.unsubscribe()
        expenseVM.unsubscribe()
        investmentVM.unsubscribe()
        buySellVM.unsubscribe()
        assetVM.unsubscribe()
        receivableVM.unsubscribe()
    }
}
