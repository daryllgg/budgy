import Foundation
import FirebaseFirestore

struct WalletTransactionService {
    nonisolated(unsafe) private static let db = Firestore.firestore()

    private static func userDoc(_ uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    /// Subscribe to all transaction types that affect a specific wallet
    static func subscribe(
        uid: String,
        walletId: String,
        year: Int,
        onChange: @escaping ([WalletTransaction]) -> Void
    ) -> [ListenerRegistration] {
        var listeners: [ListenerRegistration] = []
        var deposits: [WalletTransaction] = []
        var expenses: [WalletTransaction] = []
        var investments: [WalletTransaction] = []
        var investmentExits: [WalletTransaction] = []
        var buySells: [WalletTransaction] = []
        var receivablePayments: [WalletTransaction] = []
        var receivableOuts: [WalletTransaction] = []
        var assets: [WalletTransaction] = []
        var withdrawals: [WalletTransaction] = []

        func emit() {
            let all = (deposits + expenses + investments + investmentExits + buySells + receivablePayments + receivableOuts + assets + withdrawals)
                .sorted { $0.date > $1.date }
            onChange(all)
        }

        // 1. Deposits — walletId matches
        let depositListener = userDoc(uid).collection("deposits")
            .whereField("year", isEqualTo: year)
            .whereField("walletId", isEqualTo: walletId)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                deposits = docs.compactMap { try? $0.data(as: Deposit.self) }.map { d in
                    WalletTransaction(
                        id: "deposit_\(d.id ?? "")",
                        type: .deposit,
                        title: d.sourceLabel.isEmpty ? d.source.label : d.sourceLabel,
                        subtitle: "Deposit",
                        amount: d.amount,
                        date: d.date,
                        notes: d.notes
                    )
                }
                emit()
            }
        listeners.append(depositListener)

        // 2. Expenses — sourceId matches
        // This includes withdrawal fees (auto-created as expenses with description "Transaction Fee")
        // and the withdrawal amount itself is NOT stored as an expense — it's a direct wallet balance change.
        // We detect withdrawals by checking for "Transaction Fee" description.
        let expenseListener = userDoc(uid).collection("expenses")
            .whereField("year", isEqualTo: year)
            .whereField("sourceId", isEqualTo: walletId)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                expenses = docs.compactMap { try? $0.data(as: Expense.self) }.map { e in
                    WalletTransaction(
                        id: "expense_\(e.id ?? "")",
                        type: .expense,
                        title: e.expenseDescription,
                        subtitle: e.category.label,
                        amount: e.amount,
                        date: e.date,
                        notes: e.notes
                    )
                }
                emit()
            }
        listeners.append(expenseListener)

        // 3. Investments — sourceId matches
        let investmentListener = userDoc(uid).collection("investments")
            .whereField("year", isEqualTo: year)
            .whereField("sourceId", isEqualTo: walletId)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                investments = docs.compactMap { try? $0.data(as: Investment.self) }.map { inv in
                    WalletTransaction(
                        id: "investment_\(inv.id ?? "")",
                        type: .investment,
                        title: inv.stock,
                        subtitle: "\(inv.investmentType.label) · \(inv.source.label)",
                        amount: inv.amountPhp,
                        date: inv.date,
                        notes: inv.remarks
                    )
                }
                emit()
            }
        listeners.append(investmentListener)

        // 3b. Investment Exits (TP/SL) — wallet appears in destinations
        let exitListener = userDoc(uid).collection("investmentExits")
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let allExits = docs.compactMap { try? $0.data(as: InvestmentExit.self) }
                investmentExits = allExits.compactMap { ex in
                    guard let dest = ex.destinations.first(where: { $0.sourceId == walletId }) else { return nil }
                    let action = ex.profit >= 0 ? "TP" : "SL"
                    return WalletTransaction(
                        id: "exit_\(ex.id ?? "")",
                        type: .investmentExit,
                        title: "\(action): \(ex.stock)",
                        subtitle: "\(ex.investmentType.label) · \(action)",
                        amount: dest.amount,
                        date: ex.date,
                        notes: ex.notes
                    )
                }
                emit()
            }
        listeners.append(exitListener)

        // 4. Buy & Sell — wallet appears in fundingSources (money out) or soldDestinations (money in)
        // Firestore can't query array-of-maps by nested field, so we fetch all and filter client-side
        let buySellListener = userDoc(uid).collection("buySellTransactions")
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let allTxs = docs.compactMap { try? $0.data(as: BuySellTransaction.self) }
                var results: [WalletTransaction] = []
                for tx in allTxs {
                    // Money out: funded from this wallet
                    if let source = tx.fundingSources.first(where: { $0.sourceId == walletId }) {
                        results.append(WalletTransaction(
                            id: "buysell_\(tx.id ?? "")",
                            type: .buySell,
                            title: tx.itemName,
                            subtitle: "\(tx.itemType.label) · \(tx.status.label)",
                            amount: source.amount,
                            date: tx.dateBought ?? tx.createdAt ?? Date(),
                            notes: tx.notes
                        ))
                    }
                    // Money in: sold proceeds to this wallet
                    if let dests = tx.soldDestinations,
                       let dest = dests.first(where: { $0.sourceId == walletId }) {
                        results.append(WalletTransaction(
                            id: "buysell_in_\(tx.id ?? "")",
                            type: .buySellIn,
                            title: "Sold: \(tx.itemName)",
                            subtitle: "\(tx.itemType.label) · Sold",
                            amount: dest.amount,
                            date: tx.dateSold ?? tx.updatedAt ?? Date(),
                            notes: tx.notes
                        ))
                    }
                }
                buySells = results
                emit()
            }
        listeners.append(buySellListener)

        // 5. Receivable Payments — wallet appears in destinations
        // Similar to buy & sell, we need to fetch all receivables then their payments
        let receivableListener = userDoc(uid).collection("receivables")
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let receivables = docs.compactMap { try? $0.data(as: Receivable.self) }

                // For each receivable, listen to its payments
                var allPaymentTxs: [WalletTransaction] = []
                let group = DispatchGroup()

                for receivable in receivables {
                    guard let recId = receivable.id else { continue }
                    group.enter()
                    userDoc(uid).collection("receivables").document(recId).collection("payments")
                        .getDocuments { paymentSnap, _ in
                            defer { group.leave() }
                            guard let paymentDocs = paymentSnap?.documents else { return }
                            let payments = paymentDocs.compactMap { try? $0.data(as: ReceivablePayment.self) }
                            for payment in payments {
                                if let dest = payment.destinations.first(where: { $0.walletId == walletId }) {
                                    allPaymentTxs.append(WalletTransaction(
                                        id: "receivable_\(payment.id ?? "")",
                                        type: .receivablePayment,
                                        title: "From: \(receivable.name)",
                                        subtitle: receivable.receivableDescription,
                                        amount: dest.amount,
                                        date: payment.date,
                                        notes: payment.notes
                                    ))
                                }
                            }
                        }
                }

                group.notify(queue: .main) {
                    receivablePayments = allPaymentTxs
                    emit()
                }
            }
        listeners.append(receivableListener)

        // 6. Receivables as money out — sourceId matches (lent from this wallet)
        let receivableOutListener = userDoc(uid).collection("receivables")
            .whereField("year", isEqualTo: year)
            .whereField("sourceId", isEqualTo: walletId)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                receivableOuts = docs.compactMap { try? $0.data(as: Receivable.self) }.map { r in
                    WalletTransaction(
                        id: "receivable_out_\(r.id ?? "")",
                        type: .receivable,
                        title: "To: \(r.name)",
                        subtitle: r.receivableDescription,
                        amount: r.amount,
                        date: r.createdAt ?? Date(),
                        notes: r.notes
                    )
                }
                emit()
            }
        listeners.append(receivableOutListener)

        // 7. Assets — sourceId matches
        let assetListener = userDoc(uid).collection("assets")
            .whereField("year", isEqualTo: year)
            .whereField("sourceId", isEqualTo: walletId)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                assets = docs.compactMap { try? $0.data(as: Asset.self) }.map { a in
                    WalletTransaction(
                        id: "asset_\(a.id ?? "")",
                        type: .asset,
                        title: a.name,
                        subtitle: a.category.label,
                        amount: a.amount,
                        date: a.createdAt ?? Date(),
                        notes: a.notes
                    )
                }
                emit()
            }
        listeners.append(assetListener)

        // 7. Transfers — walletId matches bankWalletId (money out) or cashWalletId (money in)
        let withdrawalListener = userDoc(uid).collection("withdrawals")
            .whereField("year", isEqualTo: year)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let allWithdrawals = docs.compactMap { try? $0.data(as: Withdrawal.self) }
                withdrawals = allWithdrawals.compactMap { w in
                    if w.bankWalletId == walletId {
                        return WalletTransaction(
                            id: "withdrawal_bank_\(w.id ?? "")",
                            type: .withdrawal,
                            title: "Transfer to \(w.cashWalletName)",
                            subtitle: w.fee > 0 ? "Amount: \(formatPhp(w.amount)) + Fee: \(formatPhp(w.fee))" : "Transfer",
                            amount: w.amount + w.fee,
                            date: w.date,
                            notes: ""
                        )
                    } else if w.cashWalletId == walletId {
                        return WalletTransaction(
                            id: "withdrawal_cash_\(w.id ?? "")",
                            type: .withdrawalIn,
                            title: "Transfer from \(w.bankWalletName)",
                            subtitle: "Funds received",
                            amount: w.amount,
                            date: w.date,
                            notes: ""
                        )
                    }
                    return nil
                }
                emit()
            }
        listeners.append(withdrawalListener)

        return listeners
    }
}
