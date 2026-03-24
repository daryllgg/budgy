import SwiftUI
import Charts

struct BuySellAnalyticsView: View {
    var dateRange: ClosedRange<Date>?
    @Environment(AuthViewModel.self) private var authVM
    @State private var buySellVM = BuySellViewModel()

    private var filteredTransactions: [BuySellTransaction] {
        guard let range = dateRange else { return buySellVM.transactions }
        return buySellVM.transactions.filter { tx in
            if let date = tx.dateBought { return range.contains(date) }
            if let date = tx.createdAt { return range.contains(date) }
            return false
        }
    }

    private var filteredProfitByType: [ItemType: Double] {
        Dictionary(grouping: filteredTransactions.filter { $0.status == .sold }, by: \.itemType)
            .mapValues { $0.reduce(0) { $0 + ($1.profit ?? 0) } }
    }

    private var filteredSoldCount: Int { filteredTransactions.filter { $0.status == .sold }.count }
    private var filteredPendingCount: Int { filteredTransactions.filter { $0.status == .pending }.count }
    private var filteredAvailableCount: Int { filteredTransactions.filter { $0.status == .available }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Profit by item type
                if !filteredProfitByType.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Profit by Item Type")
                                .font(.headline)
                            Chart {
                                ForEach(Array(filteredProfitByType.sorted(by: { $0.value > $1.value })), id: \.key) { type, profit in
                                    BarMark(
                                        x: .value("Type", type.label),
                                        y: .value("Profit", profit)
                                    )
                                    .foregroundStyle(type.color)
                                }
                            }
                            .frame(height: 200)
                        }
                    }
                }

                // Status distribution
                if !filteredTransactions.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Status Distribution")
                                .font(.headline)
                            let statusData: [(String, Int, Color)] = [
                                ("Sold", filteredSoldCount, .green),
                                ("Pending", filteredPendingCount, .orange),
                                ("Available", filteredAvailableCount, .blue),
                            ]
                            Chart {
                                ForEach(statusData, id: \.0) { name, count, color in
                                    SectorMark(angle: .value("Count", max(count, 0)), innerRadius: .ratio(0.5))
                                        .foregroundStyle(color)
                                        .annotation(position: .overlay) {
                                            if count > 0 {
                                                Text("\(count)")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                }
                            }
                            .frame(height: 200)

                            HStack(spacing: 16) {
                                ForEach(statusData, id: \.0) { name, count, color in
                                    HStack(spacing: 4) {
                                        Circle().fill(color).frame(width: 8, height: 8)
                                        Text("\(name): \(count)").font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }

                // Top profit items
                let profitItems = filteredTransactions.filter { ($0.profit ?? 0) > 0 }.sorted(by: { ($0.profit ?? 0) > ($1.profit ?? 0) })
                if !profitItems.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Profit Items")
                                .font(.headline)
                            ForEach(profitItems.prefix(5)) { tx in
                                HStack {
                                    Text(tx.itemName)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(formatPhp(tx.profit ?? 0))
                                        .fontWeight(.semibold)
                                        .monospacedDigit()
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }

                if filteredTransactions.isEmpty && !buySellVM.isLoading {
                    Text("No transactions in this date range")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .onAppear {
            guard let uid = authVM.uid else { return }
            buySellVM.subscribe(uid: uid)
        }
        .onDisappear { buySellVM.unsubscribe() }
    }
}
