import SwiftUI

struct WalletsView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var walletVM = WalletViewModel()
    @State private var depositVM = DepositViewModel()
    @State private var showAddWallet = false
    @State private var editingWallet: Wallet?
    @State private var depositWallet: Wallet?
    @State private var deleteTarget: Wallet?

    var body: some View {
        NavigationStack {
            Group {
                if walletVM.isLoading {
                    ProgressView()
                } else if walletVM.wallets.isEmpty {
                    EmptyStateView(icon: "creditcard", title: "No Wallets", message: "Add your first wallet to start tracking")
                } else {
                    List {
                        if !walletVM.bankWallets.isEmpty {
                            Section("Bank Accounts") {
                                ForEach(walletVM.bankWallets) { wallet in
                                    NavigationLink(destination: WalletTransactionHistoryView(wallet: wallet)) {
                                        WalletRow(wallet: wallet)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) { deleteTarget = wallet } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                        Button { editingWallet = wallet } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.orange)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button { depositWallet = wallet } label: {
                                            Label("Deposit", systemImage: "plus.circle")
                                        }
                                        .tint(.green)
                                    }
                                }
                            }
                        }

                        if !walletVM.cashWallets.isEmpty {
                            Section("Cash") {
                                ForEach(walletVM.cashWallets) { wallet in
                                    NavigationLink(destination: WalletTransactionHistoryView(wallet: wallet)) {
                                        WalletRow(wallet: wallet)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) { deleteTarget = wallet } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                        Button { editingWallet = wallet } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.orange)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button { depositWallet = wallet } label: {
                                            Label("Deposit", systemImage: "plus.circle")
                                        }
                                        .tint(.green)
                                    }
                                }
                            }
                        }

                        Section {
                            HStack {
                                Text("Total Balance")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(formatPhp(walletVM.totalBalance))
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wallets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddWallet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddWallet) {
                WalletFormSheet { wallet in
                    guard let uid = authVM.uid else { return }
                    _ = await walletVM.add(uid: uid, wallet: wallet)
                }
            }
            .sheet(item: $editingWallet) { wallet in
                WalletFormSheet(wallet: wallet) { updated in
                    guard let uid = authVM.uid, let id = wallet.id else { return }
                    await walletVM.update(uid: uid, walletId: id, data: [
                        "name": updated.name,
                        "type": updated.type.rawValue,
                        "bankName": updated.bankName,
                        "balance": updated.balance,
                        "notes": updated.notes,
                    ])
                }
            }
            .sheet(item: $depositWallet) { wallet in
                DepositFormSheet(wallet: wallet) { deposit in
                    guard let uid = authVM.uid else { return }
                    _ = await depositVM.add(uid: uid, deposit: deposit)
                }
            }
            .alert("Delete Wallet?", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }), presenting: deleteTarget) { wallet in
                Button("Delete", role: .destructive) {
                    guard let uid = authVM.uid, let id = wallet.id else { return }
                    Task { await walletVM.delete(uid: uid, walletId: id) }
                }
            } message: { wallet in
                Text("This will permanently delete \"\(wallet.name)\". This action cannot be undone.")
            }
            .onAppear {
                guard let uid = authVM.uid else { return }
                walletVM.subscribe(uid: uid)
            }
            .onDisappear { walletVM.unsubscribe() }
        }
    }
}
