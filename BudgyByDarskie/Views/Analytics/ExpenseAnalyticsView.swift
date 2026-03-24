import SwiftUI
import Charts

struct ExpenseAnalyticsView: View {
    var dateRange: ClosedRange<Date>?
    @Environment(AuthViewModel.self) private var authVM
    @State private var expenseVM = ExpenseViewModel()
    @State private var selectedPoint: (date: Date, total: Double)?

    private var filteredExpenses: [Expense] {
        guard let range = dateRange else { return expenseVM.expenses }
        return expenseVM.expenses.filter { range.contains($0.date) }
    }

    private var filteredByCategory: [ExpenseCategory: Double] {
        Dictionary(grouping: filteredExpenses, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    // MARK: - Adaptive Granularity

    private enum Granularity {
        case hour, day, week, month
    }

    private var granularity: Granularity {
        guard let range = dateRange else { return .day }
        let hours = range.upperBound.timeIntervalSince(range.lowerBound) / 3600
        if hours <= 25 { return .hour }
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

    // MARK: - Trend Data

    private var trendData: [(date: Date, total: Double)] {
        let sorted = filteredExpenses.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }

        let calendar = Calendar.current
        var dataPoints: [(date: Date, total: Double)] = []
        var lastKey = -1

        for expense in sorted {
            let key = groupKey(for: expense.date, calendar: calendar)
            if key != lastKey {
                dataPoints.append((date: expense.date, total: expense.amount))
                lastKey = key
            } else {
                dataPoints[dataPoints.count - 1].total += expense.amount
            }
        }

        // Build cumulative running total
        var cumulative: [(date: Date, total: Double)] = []
        var running = 0.0
        for point in dataPoints {
            running += point.total
            cumulative.append((date: point.date, total: running))
        }

        return cumulative
    }

    private var trendYDomain: ClosedRange<Double> {
        let data = trendData
        guard !data.isEmpty else { return 0...1 }
        let values = data.map(\.total)
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 0
        let padding = max((maxVal - minVal) * 0.15, maxVal * 0.02)
        return max(0, minVal - padding)...(maxVal + padding)
    }

    private func closestTrendPoint(to date: Date) -> (date: Date, total: Double)? {
        let data = trendData
        guard !data.isEmpty else { return nil }
        return data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category breakdown donut
                if !filteredByCategory.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By Category")
                                .font(.headline)
                            Chart {
                                ForEach(Array(filteredByCategory.sorted(by: { $0.value > $1.value })), id: \.key) { cat, amount in
                                    SectorMark(angle: .value("Amount", amount), innerRadius: .ratio(0.5))
                                        .foregroundStyle(cat.color)
                                }
                            }
                            .frame(height: 200)

                            // Legend
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(Array(filteredByCategory.sorted(by: { $0.value > $1.value })), id: \.key) { cat, amount in
                                    HStack(spacing: 4) {
                                        Circle().fill(cat.color).frame(width: 8, height: 8)
                                        Text(cat.label).font(.caption)
                                        Spacer()
                                        Text(formatPhp(amount)).font(.caption).monospacedDigit()
                                    }
                                }
                            }
                        }
                    }
                }

                // Expense Trend
                if !trendData.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Expense Trend")
                                    .font(.headline)
                                Spacer()
                                if let point = selectedPoint {
                                    Text(formatPhp(point.total))
                                        .font(.subheadline.bold())
                                        .monospacedDigit()
                                        .foregroundStyle(.red)
                                }
                            }
                            if let point = selectedPoint {
                                Text(point.date.formatted(date: .abbreviated, time: granularity == .hour ? .shortened : .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Chart {
                                ForEach(Array(trendData.enumerated()), id: \.offset) { _, item in
                                    LineMark(
                                        x: .value("Date", item.date),
                                        y: .value("Amount", item.total)
                                    )
                                    .foregroundStyle(.red)
                                    .interpolationMethod(.catmullRom)
                                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                                }

                                if let point = selectedPoint {
                                    RuleMark(x: .value("Selected", point.date))
                                        .foregroundStyle(.red.opacity(0.4))
                                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                                    PointMark(
                                        x: .value("Date", point.date),
                                        y: .value("Total", point.total)
                                    )
                                    .foregroundStyle(.red)
                                    .symbolSize(60)
                                }
                            }
                            .chartYScale(domain: trendYDomain)
                            .chartYAxis {
                                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
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
                                                        selectedPoint = closestTrendPoint(to: date)
                                                    }
                                                }
                                                .onEnded { _ in }
                                        )
                                        .onTapGesture { location in
                                            let x = location.x - geo[proxy.plotFrame!].origin.x
                                            if let date: Date = proxy.value(atX: x) {
                                                if let pt = closestTrendPoint(to: date), pt.date == selectedPoint?.date {
                                                    selectedPoint = nil
                                                } else {
                                                    selectedPoint = closestTrendPoint(to: date)
                                                }
                                            }
                                        }
                                }
                            }
                            .frame(height: 220)
                        }
                    }
                }

                // Top expenses
                if !filteredExpenses.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Expenses")
                                .font(.headline)
                            ForEach(filteredExpenses.sorted(by: { $0.amount > $1.amount }).prefix(5)) { exp in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(exp.expenseDescription).font(.subheadline)
                                        Text(exp.category.label).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(formatPhp(exp.amount))
                                        .fontWeight(.semibold)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }

                if filteredExpenses.isEmpty && !expenseVM.isLoading {
                    Text("No expenses in this date range")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .onAppear {
            guard let uid = authVM.uid else { return }
            expenseVM.subscribe(uid: uid)
        }
        .onDisappear { expenseVM.unsubscribe() }
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
