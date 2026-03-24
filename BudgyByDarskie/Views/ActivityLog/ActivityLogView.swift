import SwiftUI

struct ActivityLogView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var logVM = ActivityLogViewModel()
    @State private var searchText = ""

    private func colorForType(_ type: ActivityLogType) -> Color {
        switch type {
        case .expense: .red
        case .investment: .purple
        case .deposit: .green
        case .asset: .orange
        case .buySell: .teal
        case .receivable: .cyan
        case .wallet: .indigo
        case .transfer: .mint
        case .savings: .teal
        case .payment: .green
        }
    }

    private var filteredGroups: [(date: String, logs: [ActivityLog])] {
        guard !searchText.isEmpty else { return logVM.groupedByDate }
        let term = searchText.lowercased()
        return logVM.groupedByDate.compactMap { group in
            let filtered = group.logs.filter { $0.description.lowercased().contains(term) }
            return filtered.isEmpty ? nil : (date: group.date, logs: filtered)
        }
    }

    var body: some View {
        Group {
            if logVM.isLoading {
                ProgressView()
            } else if logVM.logs.isEmpty {
                EmptyStateView(icon: "list.bullet.clipboard", title: "No Activity", message: "Your activity will appear here as you use the app")
            } else {
                List {
                    ForEach(filteredGroups, id: \.date) { group in
                        Section(group.date) {
                            ForEach(group.logs) { log in
                                HStack(spacing: 12) {
                                    Image(systemName: log.type.icon)
                                        .font(.title3)
                                        .foregroundStyle(colorForType(log.type))
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(log.description)
                                            .font(.subheadline)
                                            .lineLimit(2)
                                        HStack(spacing: 6) {
                                            Text(log.type.label)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text("·")
                                                .foregroundStyle(.secondary)
                                            Text(log.createdAt?.formatted(date: .omitted, time: .shortened) ?? "")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if let amount = log.amount {
                                        Text(formatPhp(amount))
                                            .font(.subheadline.weight(.semibold))
                                            .monospacedDigit()
                                            .foregroundStyle(log.action == .delete ? .red : .primary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search activity...")
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Activity Log")
        .refreshable {
            guard let uid = authVM.uid else { return }
            logVM.subscribe(uid: uid)
        }
        .onAppear {
            guard let uid = authVM.uid else { return }
            logVM.subscribe(uid: uid)
        }
        .onDisappear { logVM.unsubscribe() }
    }
}
