import SwiftUI

struct ExpenseSummaryCard: View {
    let expenses: [Expense]

    private var todayTotal: Double {
        expenses
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    private var thisWeekTotal: Double {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        return expenses
            .filter { $0.date >= interval.start && $0.date < interval.end }
            .reduce(0) { $0 + $1.amount }
    }

    private var thisMonthTotal: Double {
        guard let interval = Calendar.current.dateInterval(of: .month, for: Date()) else { return 0 }
        return expenses
            .filter { $0.date >= interval.start && $0.date < interval.end }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        HStack(spacing: 0) {
            summaryItem(label: "Today", amount: todayTotal)
            Divider().frame(height: 36)
            summaryItem(label: "This Week", amount: thisWeekTotal)
            Divider().frame(height: 36)
            summaryItem(label: "This Month", amount: thisMonthTotal)
        }
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .padding(.horizontal)
    }

    private func summaryItem(label: String, amount: Double) -> some View {
        VStack(spacing: 4) {
            Text(formatPhp(amount))
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(amount > 0 ? AppTheme.negative : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
