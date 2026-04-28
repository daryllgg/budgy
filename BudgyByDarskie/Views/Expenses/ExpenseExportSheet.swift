import SwiftUI

struct ExpenseExportSheet: View {
    let expenses: [Expense]
    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false

    private var filteredExpenses: [Expense] {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
        return expenses
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.date < $1.date }
    }

    private var total: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                }

                Section {
                    HStack {
                        Text("Expenses found")
                        Spacer()
                        Text("\(filteredExpenses.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(formatPhp(total))
                            .fontWeight(.semibold)
                    }
                }

                Section {
                    if let url = exportedFileURL {
                        ShareLink(item: url) {
                            HStack {
                                Spacer()
                                Label("Share File", systemImage: "square.and.arrow.up")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }

                    Button {
                        exportCSV()
                    } label: {
                        HStack {
                            Spacer()
                            Label(exportedFileURL == nil ? "Generate Excel File (.csv)" : "Regenerate File", systemImage: "arrow.down.doc")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(filteredExpenses.isEmpty)
                }
            }
            .navigationTitle("Export Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: startDate) { exportedFileURL = nil }
            .onChange(of: endDate) { exportedFileURL = nil }
        }
    }

    private func exportCSV() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        var csv = "Date,Time,Description,Category,Amount,Source Wallet,Notes\n"

        for expense in filteredExpenses {
            let date = dateFormatter.string(from: expense.date)
            let time = timeFormatter.string(from: expense.date)
            let desc = csvEscape(expense.expenseDescription)
            let category = expense.category.label
            let amount = String(format: "%.2f", expense.amount)
            let source = csvEscape(expense.sourceName)
            let notes = csvEscape(expense.notes)
            csv += "\(date),\(time),\(desc),\(category),\(amount),\(source),\(notes)\n"
        }

        csv += "\n,,,,\(String(format: "%.2f", total)),,TOTAL\n"

        let rangeStart = dateFormatter.string(from: startDate)
        let rangeEnd = dateFormatter.string(from: endDate)
        let fileName = "Expenses_\(rangeStart)_to_\(rangeEnd).csv"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            exportedFileURL = tempURL
        } catch {
            // File write error
        }
    }

    private func csvEscape(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }
}
