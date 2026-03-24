import SwiftUI

struct AnalyticsView: View {
    @State private var selectedTab = 0
    @State private var dateFilter: AnalyticsDateFilter = .all
    @State private var customStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEnd: Date = Date()
    @State private var showDatePicker = false

    var dateRange: ClosedRange<Date>? {
        let calendar = Calendar.current
        switch dateFilter {
        case .all:
            return nil
        case .today:
            let start = calendar.startOfDay(for: Date())
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return start...end
        case .thisWeek:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return nil }
            return interval.start...interval.end
        case .thisMonth:
            guard let interval = calendar.dateInterval(of: .month, for: Date()) else { return nil }
            return interval.start...interval.end
        case .thisYear:
            guard let interval = calendar.dateInterval(of: .year, for: Date()) else { return nil }
            return interval.start...interval.end
        case .custom:
            return calendar.startOfDay(for: customStart)...calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEnd))!
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Analytics", selection: $selectedTab) {
                    Text("Overall").tag(0)
                    Text("Buy & Sell").tag(1)
                    Text("Investments").tag(2)
                    Text("Expenses").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                // Date filter
                dateFilterBar
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                switch selectedTab {
                case 0: OverallAnalyticsView(dateRange: dateRange)
                case 1: BuySellAnalyticsView(dateRange: dateRange)
                case 2: InvestmentAnalyticsView(dateRange: dateRange)
                case 3: ExpenseAnalyticsView(dateRange: dateRange)
                default: EmptyView()
                }

                Spacer()
            }
            .navigationTitle("Analytics")
            .sheet(isPresented: $showDatePicker) {
                customDatePickerSheet
            }
        }
    }

    // MARK: - Date Filter Bar

    private var dateFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                ForEach(AnalyticsDateFilter.allCases, id: \.self) { filter in
                    Button {
                        if filter == .custom {
                            showDatePicker = true
                        } else {
                            dateFilter = filter
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if filter == .custom && dateFilter == .custom {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(dateRangeLabel)
                            } else {
                                Text(filter.label)
                            }
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .foregroundStyle(dateFilter == filter ? .white : .primary)
                        .background(dateFilter == filter ? AppTheme.accent : Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(dateFilter == filter ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var dateRangeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "\(f.string(from: customStart)) – \(f.string(from: customEnd))"
    }

    // MARK: - Custom Date Picker Sheet

    private var customDatePickerSheet: some View {
        NavigationStack {
            Form {
                DatePicker("Start Date", selection: $customStart, displayedComponents: .date)
                DatePicker("End Date", selection: $customEnd, in: customStart..., displayedComponents: .date)
            }
            .navigationTitle("Custom Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showDatePicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        dateFilter = .custom
                        showDatePicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

enum AnalyticsDateFilter: CaseIterable {
    case all, today, thisWeek, thisMonth, thisYear, custom

    var label: String {
        switch self {
        case .all: "All Time"
        case .today: "Today"
        case .thisWeek: "This Week"
        case .thisMonth: "This Month"
        case .thisYear: "This Year"
        case .custom: "Custom"
        }
    }
}
