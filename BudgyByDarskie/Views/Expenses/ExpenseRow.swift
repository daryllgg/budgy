import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: expense.category.icon)
                .font(.body)
                .foregroundStyle(expense.category.color)
                .frame(width: 36, height: 36)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.expenseDescription)
                    .fontWeight(.semibold)
                HStack(spacing: 6) {
                    Text(expense.category.label)
                        .font(.caption)
                        .foregroundStyle(expense.category.color)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(expense.sourceName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(formatPhp(expense.amount))
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .monospacedDigit()
                Text(expense.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? expense.date.formattedMMddyy())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
