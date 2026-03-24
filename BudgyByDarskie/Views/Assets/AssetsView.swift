import SwiftUI

struct AssetsView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(ToastManager.self) private var toast
    @State private var assetVM = AssetViewModel()
    @State private var walletVM = WalletViewModel()
    @State private var showAddAsset = false
    @State private var editingAsset: Asset?
    @State private var deleteTarget: Asset?

    // Filters
    @State private var sortBy: AssetSortOption = .defaultOrder
    @State private var filterCategory: AssetCategory?

    private var hasActiveFilters: Bool {
        filterCategory != nil || sortBy != .defaultOrder
    }

    private var filteredAssets: [Asset] {
        var result = assetVM.assets

        if let cat = filterCategory {
            result = result.filter { $0.category == cat }
        }

        switch sortBy {
        case .defaultOrder: break
        case .amountHigh: result.sort { $0.amount > $1.amount }
        case .amountLow: result.sort { $0.amount < $1.amount }
        case .nameAZ: result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        return result
    }

    var body: some View {
        Group {
            if assetVM.isLoading {
                ProgressView()
            } else if assetVM.assets.isEmpty {
                EmptyStateView(icon: "cube.box", title: "No Assets", message: "Add your first asset")
            } else {
                List {
                    if filterCategory != nil {
                        // Show flat list when filtering by category
                        Section("Total: \(formatPhp(filteredAssets.reduce(0) { $0 + $1.amount }))") {
                            ForEach(filteredAssets) { asset in
                                AssetRow(asset: asset)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) { deleteTarget = asset } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        Button { editingAsset = asset } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.orange)
                                    }
                            }
                        }
                    } else {
                        ForEach(AssetCategory.allCases, id: \.self) { category in
                            let assets = (sortBy == .defaultOrder ? assetVM.byCategory[category] ?? [] : filteredAssets.filter { $0.category == category })
                            if !assets.isEmpty {
                                Section(category.label) {
                                    ForEach(assets) { asset in
                                        AssetRow(asset: asset)
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) { deleteTarget = asset } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                                Button { editingAsset = asset } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                .tint(.orange)
                                            }
                                    }
                                }
                            }
                        }
                    }

                    Section {
                        HStack {
                            Text("Total Assets")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatPhp(assetVM.totalAssets))
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .navigationTitle("Assets")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Menu {
                        Section("Sort By") {
                            ForEach(AssetSortOption.allCases, id: \.self) { option in
                                Button {
                                    sortBy = option
                                } label: {
                                    Label(option.label, systemImage: sortBy == option ? "checkmark" : "")
                                }
                            }
                        }
                        Section("Category") {
                            Button {
                                filterCategory = nil
                            } label: {
                                Label("All Categories", systemImage: filterCategory == nil ? "checkmark" : "")
                            }
                            ForEach(AssetCategory.allCases, id: \.self) { cat in
                                Button {
                                    filterCategory = cat
                                } label: {
                                    Label(cat.label, systemImage: filterCategory == cat ? "checkmark" : cat.icon)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    Button { showAddAsset = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddAsset) {
            AssetFormSheet(wallets: walletVM.wallets) { asset in
                guard let uid = authVM.uid else { return }
                let docId = await assetVM.add(uid: uid, asset: asset)
                if let docId {
                    hapticSuccess()
                    toast.show("Asset added") {
                        await assetVM.delete(uid: uid, assetId: docId, sourceId: asset.sourceId, amount: asset.amount)
                    }
                }
            }
        }
        .sheet(item: $editingAsset) { asset in
            AssetFormSheet(wallets: walletVM.wallets, asset: asset) { updated in
                guard let uid = authVM.uid, let id = asset.id else { return }
                await assetVM.update(uid: uid, assetId: id, oldAmount: asset.amount, oldSourceId: asset.sourceId, asset: updated)
                hapticSuccess()
                toast.show("Asset updated")
            }
        }
        .alert("Delete Asset?", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }), presenting: deleteTarget) { asset in
            Button("Delete", role: .destructive) {
                guard let uid = authVM.uid, let id = asset.id else { return }
                Task {
                    await assetVM.delete(uid: uid, assetId: id, sourceId: asset.sourceId, amount: asset.amount)
                    hapticSuccess()
                    toast.show("Asset deleted")
                }
            }
        } message: { asset in
            Text("This will permanently delete \"\(asset.name)\".")
        }
        .refreshable {
            guard let uid = authVM.uid else { return }
            assetVM.subscribe(uid: uid)
            walletVM.subscribe(uid: uid)
        }
        .onAppear {
            guard let uid = authVM.uid else { return }
            assetVM.subscribe(uid: uid)
            walletVM.subscribe(uid: uid)
        }
        .onDisappear {
            assetVM.unsubscribe()
            walletVM.unsubscribe()
        }
    }
}

enum AssetSortOption: CaseIterable {
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
