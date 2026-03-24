import SwiftUI

struct ReceivablesView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(ToastManager.self) private var toast
    @State private var receivableVM = ReceivableViewModel()
    @State private var walletVM = WalletViewModel()
    @State private var showAddReceivable = false
    @State private var selectedTab = 0

    // Filters
    @State private var sortBy: ReceivableSortOption = .defaultOrder
    @State private var filterReimbursement: Bool?

    private var hasActiveFilters: Bool {
        filterReimbursement != nil || sortBy != .defaultOrder
    }

    private var filteredReceivables: [Receivable] {
        var result = receivableVM.receivables

        if let isReimb = filterReimbursement {
            result = result.filter { $0.isReimbursement == isReimb }
        }

        switch sortBy {
        case .defaultOrder: break
        case .amountHigh: result.sort { $0.amount > $1.amount }
        case .amountLow: result.sort { $0.amount < $1.amount }
        case .nameAZ: result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        return result
    }

    private var groupedByPerson: [PersonGroup] {
        let grouped = Dictionary(grouping: filteredReceivables, by: { $0.name })
        var groups = grouped.map { PersonGroup(name: $0.key, receivables: $0.value) }
        switch sortBy {
        case .amountHigh: groups.sort { $0.totalAmount > $1.totalAmount }
        case .amountLow: groups.sort { $0.totalAmount < $1.totalAmount }
        case .nameAZ, .defaultOrder: groups.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        return groups
    }

    private var ongoingGroups: [PersonGroup] {
        groupedByPerson.filter { !$0.isCompleted }
    }

    private var completedGroups: [PersonGroup] {
        groupedByPerson.filter { $0.isCompleted }
    }

    private var displayedGroups: [PersonGroup] {
        selectedTab == 0 ? ongoingGroups : completedGroups
    }

    var body: some View {
        Group {
            if receivableVM.isLoading {
                ProgressView()
            } else if receivableVM.receivables.isEmpty {
                EmptyStateView(icon: "person.2", title: "No Receivables", message: "Add receivables to track money owed to you")
            } else {
                VStack(spacing: 0) {
                    Picker("Status", selection: $selectedTab) {
                        Text("Ongoing (\(ongoingGroups.count))").tag(0)
                        Text("Completed (\(completedGroups.count))").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    if displayedGroups.isEmpty {
                        Spacer()
                        Text(selectedTab == 0 ? "No ongoing receivables" : "No completed receivables")
                            .foregroundStyle(.secondary)
                        Spacer()
                    } else {
                        List {
                            Section(selectedTab == 0 ? "Total: \(formatPhp(displayedGroups.reduce(0) { $0 + $1.remaining }))" : "") {
                                ForEach(displayedGroups) { group in
                                    NavigationLink {
                                        PersonReceivablesView(
                                            personName: group.name,
                                            walletVM: walletVM
                                        )
                                    } label: {
                                        PersonRow(group: group)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Receivables")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Menu {
                        Section("Sort By") {
                            ForEach(ReceivableSortOption.allCases, id: \.self) { option in
                                Button {
                                    sortBy = option
                                } label: {
                                    Label(option.label, systemImage: sortBy == option ? "checkmark" : "")
                                }
                            }
                        }
                        Section("Type") {
                            Button {
                                filterReimbursement = nil
                            } label: {
                                Label("All", systemImage: filterReimbursement == nil ? "checkmark" : "")
                            }
                            Button {
                                filterReimbursement = true
                            } label: {
                                Label("Reimbursements", systemImage: filterReimbursement == true ? "checkmark" : "")
                            }
                            Button {
                                filterReimbursement = false
                            } label: {
                                Label("Non-Reimbursements", systemImage: filterReimbursement == false ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    Button { showAddReceivable = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddReceivable) {
            ReceivableFormSheet(wallets: walletVM.wallets) { rec in
                guard let uid = authVM.uid else { return }
                let docId = await receivableVM.add(uid: uid, receivable: rec)
                if let docId {
                    hapticSuccess()
                    toast.show("Receivable added") {
                        await receivableVM.delete(uid: uid, receivableId: docId, sourceId: rec.sourceId, amount: rec.amount)
                    }
                }
            }
        }
        .refreshable {
            guard let uid = authVM.uid else { return }
            receivableVM.subscribe(uid: uid)
            walletVM.subscribe(uid: uid)
        }
        .onAppear {
            guard let uid = authVM.uid else { return }
            receivableVM.subscribe(uid: uid)
            walletVM.subscribe(uid: uid)
        }
        .onDisappear {
            receivableVM.unsubscribe()
            walletVM.unsubscribe()
        }
    }
}

struct PersonRow: View {
    let group: PersonGroup

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .fontWeight(.semibold)
                Text("\(group.count) receivable\(group.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatPhp(group.remaining))
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(group.remaining > 0 ? .orange : .green)
        }
    }
}

struct PersonGroup: Identifiable {
    var id: String { name }
    let name: String
    let receivables: [Receivable]
    var totalAmount: Double { receivables.reduce(0) { $0 + $1.amount } }
    var totalPaid: Double { receivables.reduce(0) { $0 + ($1.totalPaid ?? 0) } }
    var remaining: Double { totalAmount - totalPaid }
    var count: Int { receivables.count }
    var isCompleted: Bool { remaining <= 0 }
}

enum ReceivableSortOption: CaseIterable {
    case defaultOrder, amountHigh, amountLow, nameAZ

    var label: String {
        switch self {
        case .defaultOrder: "Default"
        case .amountHigh: "Amount (High → Low)"
        case .amountLow: "Amount (Low → High)"
        case .nameAZ: "Name (A → Z)"
        }
    }
}
