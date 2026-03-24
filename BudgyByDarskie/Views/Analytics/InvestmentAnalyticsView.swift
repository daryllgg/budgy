import SwiftUI
import Charts

struct InvestmentAnalyticsView: View {
    var dateRange: ClosedRange<Date>?
    @Environment(AuthViewModel.self) private var authVM
    @State private var investmentVM = InvestmentViewModel()

    private var filteredInvestments: [Investment] {
        guard let range = dateRange else { return investmentVM.investments }
        return investmentVM.investments.filter { range.contains($0.date) }
    }

    private var filteredBySource: [InvestmentSource: Double] {
        Dictionary(grouping: filteredInvestments, by: \.source)
            .mapValues { $0.reduce(0) { $0 + $1.amountPhp } }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Investment by source
                if !filteredBySource.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Investment by Source")
                                .font(.headline)
                            Chart {
                                ForEach(Array(filteredBySource.sorted(by: { $0.value > $1.value })), id: \.key) { source, amount in
                                    SectorMark(angle: .value("Amount", amount), innerRadius: .ratio(0.5))
                                        .foregroundStyle(by: .value("Source", source.label))
                                }
                            }
                            .frame(height: 200)
                        }
                    }
                }

                // Monthly investment chart
                if !filteredInvestments.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Monthly Investments (PHP)")
                                .font(.headline)
                            Chart {
                                ForEach(monthlyData, id: \.month) { item in
                                    BarMark(
                                        x: .value("Month", item.month),
                                        y: .value("Amount", item.total)
                                    )
                                    .foregroundStyle(.purple)
                                }
                            }
                            .frame(height: 200)
                        }
                    }
                }

                // Investment type breakdown
                let typeGroups = Dictionary(grouping: filteredInvestments, by: \.investmentType)
                if !typeGroups.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By Investment Type")
                                .font(.headline)
                            ForEach(Array(typeGroups.sorted(by: { $0.value.reduce(0) { $0 + $1.amountPhp } > $1.value.reduce(0) { $0 + $1.amountPhp } })), id: \.key) { type, items in
                                HStack {
                                    CategoryBadge(label: type.label, color: type.color, icon: "chart.bar")
                                    Spacer()
                                    Text(formatPhp(items.reduce(0) { $0 + $1.amountPhp }))
                                        .fontWeight(.semibold)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }

                if filteredInvestments.isEmpty && !investmentVM.isLoading {
                    Text("No investments in this date range")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .onAppear {
            guard let uid = authVM.uid else { return }
            investmentVM.subscribe(uid: uid)
        }
        .onDisappear { investmentVM.unsubscribe() }
    }

    private var monthlyData: [(month: String, total: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredInvestments) { inv in
            calendar.component(.month, from: inv.date)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return (1...12).compactMap { month in
            let total = grouped[month]?.reduce(0) { $0 + $1.amountPhp } ?? 0
            guard total > 0 else { return nil }
            var comps = DateComponents()
            comps.month = month
            let date = calendar.date(from: comps) ?? Date()
            return (month: formatter.string(from: date), total: total)
        }
    }
}
