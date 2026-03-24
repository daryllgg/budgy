import SwiftUI

struct WalletTransactionHistoryView: View {
    let wallet: Wallet
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm = WalletTransactionViewModel()
    @State private var filter: TransactionFilter = .all

    enum TransactionFilter: CaseIterable {
        case all, moneyIn, moneyOut

        var label: String {
            switch self {
            case .all: "All"
            case .moneyIn: "Money In"
            case .moneyOut: "Money Out"
            }
        }
    }

    private var filteredTransactions: [WalletTransaction] {
        switch filter {
        case .all: vm.transactions
        case .moneyIn: vm.transactions.filter { $0.type.isInflow }
        case .moneyOut: vm.transactions.filter { !$0.type.isInflow }
        }
    }

    private var filteredGroupedByMonth: [(key: String, transactions: [WalletTransaction])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: filteredTransactions) { formatter.string(from: $0.date) }

        return grouped
            .sorted { lhs, rhs in
                guard let lDate = lhs.value.first?.date, let rDate = rhs.value.first?.date else { return false }
                return lDate > rDate
            }
            .map { (key: $0.key, transactions: $0.value) }
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if vm.transactions.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "No Transactions",
                    message: "Transactions will appear here when you add deposits, expenses, or other activity."
                )
            } else {
                List {
                    // Summary card
                    Section {
                        summaryCard
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .padding(.top, 24)
                    }

                    // Filter picker
                    Section {
                        Picker("Filter", selection: $filter) {
                            ForEach(TransactionFilter.allCases, id: \.self) { f in
                                Text(f.label).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }

                    // Grouped transactions
                    if filteredTransactions.isEmpty {
                        Section {
                            Text("No \(filter.label.lowercased()) transactions")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        }
                    } else {
                        ForEach(filteredGroupedByMonth, id: \.key) { group in
                            Section(group.key) {
                                ForEach(group.transactions) { tx in
                                    TransactionRow(transaction: tx)
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(wallet.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            guard let uid = authVM.uid, let walletId = wallet.id else { return }
            vm.subscribe(uid: uid, walletId: walletId)
        }
        .onDisappear {
            vm.unsubscribe()
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: wallet.type == .bank ? "building.columns.fill" : "banknote.fill")
                    .font(.title3)
                    .foregroundStyle(wallet.type == .bank ? AppTheme.wallets : AppTheme.positive)
                VStack(alignment: .leading, spacing: 2) {
                    Text(wallet.name)
                        .font(.headline)
                    if !wallet.bankName.isEmpty {
                        Text(wallet.bankName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(wallet.type.label)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassEffect(.regular, in: .capsule)
            }

            Divider()

            HStack {
                Text("Balance")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatPhp(wallet.balance))
                    .font(.title2.bold())
                    .monospacedDigit()
            }

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(AppTheme.positive)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Total In")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(formatPhp(vm.totalIn))
                            .font(.caption.bold())
                            .monospacedDigit()
                    }
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(AppTheme.negative)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Total Out")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(formatPhp(vm.totalOut))
                            .font(.caption.bold())
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Transaction Row

private struct TransactionRow: View {
    let transaction: WalletTransaction

    private var iconColor: Color {
        transaction.type.isInflow ? AppTheme.positive : AppTheme.negative
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.type.icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(transaction.subtitle)
                    Text("·")
                    Text(transaction.date.formattedMMMddyyyy())
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(transaction.type.isInflow ? "+" : "-")\(formatPhp(transaction.amount))")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(transaction.type.isInflow ? AppTheme.positive : AppTheme.negative)
        }
        .padding(.vertical, 2)
    }
}
