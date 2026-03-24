import SwiftUI

struct ExpenseDetailSheet: View {
    let expense: Expense
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: expense.category.icon)
                            .font(.title)
                            .foregroundStyle(expense.category.color)
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular, in: .circle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.expenseDescription)
                                .font(.headline)
                            Text(expense.category.label)
                                .font(.subheadline)
                                .foregroundStyle(expense.category.color)
                        }
                        Spacer()
                    }
                }

                Section {
                    LabeledContent("Amount") {
                        Text(formatPhp(expense.amount))
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    LabeledContent("Date") {
                        Text(expense.date.formattedMMMddyyyy())
                    }
                    LabeledContent("Source Wallet") {
                        Text(expense.sourceName)
                    }
                    LabeledContent("Category") {
                        Text(expense.category.label)
                    }
                }

                if !expense.notes.isEmpty {
                    Section("Notes") {
                        Text(expense.notes)
                            .foregroundStyle(.secondary)
                    }
                }

                if let createdAt = expense.createdAt {
                    Section {
                        LabeledContent("Created") {
                            Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Expense Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}
