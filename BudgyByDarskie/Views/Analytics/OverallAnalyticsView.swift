import SwiftUI
import Charts

struct OverallAnalyticsView: View {
    var dateRange: ClosedRange<Date>?
    @Environment(AuthViewModel.self) private var authVM
    @State private var depositVM = DepositViewModel()
    @State private var expenseVM = ExpenseViewModel()
    @State private var investmentVM = InvestmentViewModel()
    @State private var assetVM = AssetViewModel()
    @State private var receivableVM = ReceivableViewModel()
    @State private var buySellVM = BuySellViewModel()
    @State private var walletVM = WalletViewModel()
    @State private var selectedPoint: (date: Date, total: Double)?

    private var currentGrandTotal: Double {
        walletVM.totalBalance + investmentVM.totalInvestedPhp + receivableVM.totalReceivables + assetVM.totalAssets + buySellVM.totalInventoryValue
    }

    private struct TimelineEvent {
        let date: Date
        let delta: Double
    }

    /// Determine grouping granularity based on the date filter span
    private enum Granularity {
        case hour, day, week, month
    }

    private var granularity: Granularity {
        guard let range = dateRange else { return .day } // All Time → daily
        let span = range.upperBound.timeIntervalSince(range.lowerBound)
        let hours = span / 3600
        if hours <= 25 { return .hour }
        if hours <= 24 * 8 { return .day }
        if hours <= 24 * 32 { return .day }
        if hours <= 24 * 366 { return .week }
        return .month
    }

    private func groupKey(for date: Date, calendar: Calendar) -> Int {
        switch granularity {
        case .hour:
            let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
            let hour = calendar.component(.hour, from: date)
            return day * 100 + hour
        case .day:
            return calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        case .week:
            let year = calendar.component(.yearForWeekOfYear, from: date)
            let week = calendar.component(.weekOfYear, from: date)
            return year * 100 + week
        case .month:
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            return year * 100 + month
        }
    }

    private var timelineData: [(date: Date, total: Double)] {
        var events: [TimelineEvent] = []

        for d in depositVM.deposits {
            events.append(TimelineEvent(date: d.date, delta: d.amount))
        }

        for e in expenseVM.expenses {
            events.append(TimelineEvent(date: e.date, delta: -e.amount))
        }

        for a in assetVM.assets {
            if a.sourceId.isEmpty, let created = a.createdAt {
                events.append(TimelineEvent(date: created, delta: a.amount))
            }
        }

        for r in receivableVM.receivables {
            if r.sourceId.isEmpty, let created = r.createdAt {
                events.append(TimelineEvent(date: created, delta: r.amount))
            }
        }

        for tx in buySellVM.transactions {
            if let dateBought = tx.dateBought {
                events.append(TimelineEvent(date: dateBought, delta: -tx.buyPrice))
            }
            if let dateSold = tx.dateSold, let sellPrice = tx.sellPrice {
                events.append(TimelineEvent(date: dateSold, delta: sellPrice))
            }
        }

        events.sort { $0.date < $1.date }

        let filtered: [TimelineEvent]
        if let range = dateRange {
            filtered = events.filter { range.contains($0.date) }
        } else {
            filtered = events
        }

        guard !filtered.isEmpty else { return [] }

        let totalDelta = events.reduce(0.0) { $0 + $1.delta }
        let startingBalance = currentGrandTotal - totalDelta

        var runningTotal = startingBalance
        var dataPoints: [(date: Date, total: Double)] = []

        let calendar = Calendar.current
        var lastKey = -1

        for event in events {
            runningTotal += event.delta

            if let range = dateRange, !range.contains(event.date) {
                continue
            }

            let key = groupKey(for: event.date, calendar: calendar)

            if key != lastKey {
                dataPoints.append((date: event.date, total: runningTotal))
                lastKey = key
            } else {
                dataPoints[dataPoints.count - 1] = (date: dataPoints.last!.date, total: runningTotal)
            }
        }

        // Add "now" endpoint
        if let last = dataPoints.last {
            let nowKey = groupKey(for: Date(), calendar: calendar)
            if nowKey != lastKey {
                dataPoints.append((date: Date(), total: last.total))
            }
        }

        return dataPoints
    }

    private var yDomain: ClosedRange<Double> {
        let data = timelineData
        guard !data.isEmpty else { return 0...1 }
        let values = data.map(\.total)
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 0
        let spread = maxVal - minVal
        let padding = max(spread * 0.15, maxVal * 0.02)
        return max(0, minVal - padding)...(maxVal + padding)
    }

    private var stats: (highest: Double, lowest: Double, growth: Double) {
        let data = timelineData
        guard !data.isEmpty else { return (0, 0, 0) }
        let highest = data.map(\.total).max() ?? 0
        let lowest = data.map(\.total).min() ?? 0
        let growth = (data.last?.total ?? 0) - (data.first?.total ?? 0)
        return (highest, lowest, growth)
    }

    private func closestPoint(to date: Date) -> (date: Date, total: Double)? {
        let data = timelineData
        guard !data.isEmpty else { return nil }
        return data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current Grand Total or Selected Point
                GlassCard {
                    VStack(spacing: 8) {
                        if let point = selectedPoint {
                            Text(point.date.formatted(date: .abbreviated, time: granularity == .hour ? .shortened : .omitted))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(formatPhp(point.total))
                                .font(.title.bold())
                                .monospacedDigit()
                                .foregroundStyle(AppTheme.accent)
                        } else {
                            Text("Grand Total")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(formatPhp(currentGrandTotal))
                                .font(.title.bold())
                                .monospacedDigit()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .animation(.easeInOut(duration: 0.15), value: selectedPoint?.date)
                }

                // Line Chart
                if !timelineData.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Balance Trend")
                                    .font(.headline)
                                Spacer()
                                if selectedPoint != nil {
                                    Button("Reset") { selectedPoint = nil }
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                            Chart {
                                ForEach(Array(timelineData.enumerated()), id: \.offset) { _, item in
                                    LineMark(
                                        x: .value("Date", item.date),
                                        y: .value("Total", item.total)
                                    )
                                    .foregroundStyle(AppTheme.accent)
                                    .interpolationMethod(.catmullRom)
                                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                                }

                                if let point = selectedPoint {
                                    RuleMark(x: .value("Selected", point.date))
                                        .foregroundStyle(AppTheme.accent.opacity(0.4))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                                    PointMark(
                                        x: .value("Date", point.date),
                                        y: .value("Total", point.total)
                                    )
                                    .foregroundStyle(AppTheme.accent)
                                    .symbolSize(60)
                                }
                            }
                            .chartYScale(domain: yDomain)
                            .chartYAxis {
                                AxisMarks(position: .leading, values: .automatic(desiredCount: 6)) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                    AxisValueLabel {
                                        if let v = value.as(Double.self) {
                                            Text(formatCompact(v))
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                                    AxisValueLabel {
                                        if let d = value.as(Date.self) {
                                            Text(formatDateAxis(d))
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .chartOverlay { proxy in
                                GeometryReader { geo in
                                    Rectangle().fill(.clear).contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { drag in
                                                    let x = drag.location.x - geo[proxy.plotFrame!].origin.x
                                                    if let date: Date = proxy.value(atX: x) {
                                                        selectedPoint = closestPoint(to: date)
                                                    }
                                                }
                                                .onEnded { _ in }
                                        )
                                        .onTapGesture { location in
                                            let x = location.x - geo[proxy.plotFrame!].origin.x
                                            if let date: Date = proxy.value(atX: x) {
                                                if let pt = closestPoint(to: date), pt.date == selectedPoint?.date {
                                                    selectedPoint = nil
                                                } else {
                                                    selectedPoint = closestPoint(to: date)
                                                }
                                            }
                                        }
                                }
                            }
                            .frame(height: 260)
                        }
                    }
                }

                // Stats
                GlassCard {
                    VStack(spacing: 12) {
                        HStack {
                            StatItem(label: "Highest", value: formatPhp(stats.highest), color: .green)
                            Spacer()
                            StatItem(label: "Lowest", value: formatPhp(stats.lowest), color: .red)
                        }
                        HStack {
                            StatItem(label: "Growth", value: formatPhp(stats.growth), color: stats.growth >= 0 ? .green : .red)
                            Spacer()
                            StatItem(label: "Data Points", value: "\(timelineData.count)", color: .blue)
                        }
                    }
                }

                if timelineData.isEmpty && !depositVM.isLoading {
                    Text("No data available for this period")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .onAppear {
            guard let uid = authVM.uid else { return }
            depositVM.subscribe(uid: uid)
            expenseVM.subscribe(uid: uid)
            investmentVM.subscribe(uid: uid, year: nil)
            assetVM.subscribe(uid: uid)
            receivableVM.subscribe(uid: uid)
            buySellVM.subscribe(uid: uid)
            walletVM.subscribe(uid: uid)
        }
        .onDisappear {
            depositVM.unsubscribe()
            expenseVM.unsubscribe()
            investmentVM.unsubscribe()
            assetVM.unsubscribe()
            receivableVM.unsubscribe()
            buySellVM.unsubscribe()
            walletVM.unsubscribe()
        }
    }

    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 { return "\(formatNumber(value / 1_000_000))M" }
        if value >= 1_000 { return "\(formatNumber(value / 1_000))K" }
        return formatNumber(value)
    }

    private func formatDateAxis(_ date: Date) -> String {
        let f = DateFormatter()
        switch granularity {
        case .hour: f.dateFormat = "ha"
        case .day: f.dateFormat = "MMM d"
        case .week: f.dateFormat = "MMM d"
        case .month: f.dateFormat = "MMM yy"
        }
        return f.string(from: date)
    }
}

private struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }
}
