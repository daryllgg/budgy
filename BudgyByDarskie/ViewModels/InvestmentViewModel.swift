import Foundation
import FirebaseFirestore

@Observable
class InvestmentViewModel {
    var investments: [Investment] = []
    var allInvestments: [Investment] = []
    var isLoading = true
    var errorMessage: String?

    private var listener: ListenerRegistration?
    private var allListener: ListenerRegistration?

    var totalInvestedPhp: Double { investments.reduce(0) { $0 + $1.amountPhp } }
    var totalInvestedUsd: Double { investments.reduce(0) { $0 + $1.amountUsd } }

    var portfolio: PortfolioSummary {
        let stocks = allInvestments.filter { $0.investmentType == .stock && $0.stock == "VOO" }
        let totalPhp = stocks.reduce(0) { $0 + $1.amountPhp }
        let totalUsd = stocks.reduce(0) { $0 + $1.amountUsd }
        let totalCostBasis = stocks.reduce(0) { $0 + ($1.buyPrice * $1.quantity) }
        let totalQty = stocks.reduce(0) { $0 + $1.quantity }
        let avgPrice = totalQty > 0 ? totalCostBasis / totalQty : 0
        return PortfolioSummary(
            totalInvestedPhp: totalPhp,
            totalInvestedUsd: totalUsd,
            totalCostBasis: totalCostBasis,
            averageBuyPrice: avgPrice,
            totalQuantity: totalQty
        )
    }

    var bySource: [InvestmentSource: Double] {
        Dictionary(grouping: investments, by: \.source)
            .mapValues { $0.reduce(0) { $0 + $1.amountPhp } }
    }

    func subscribe(uid: String, year: Int? = CURRENT_YEAR) {
        listener?.remove()
        isLoading = true
        listener = InvestmentService.subscribe(uid: uid, year: year) { [weak self] investments in
            self?.investments = investments
            self?.isLoading = false
        }
    }

    func subscribeAll(uid: String) {
        allListener?.remove()
        allListener = InvestmentService.subscribe(uid: uid, year: nil) { [weak self] investments in
            self?.allInvestments = investments
        }
    }

    func unsubscribe() {
        listener?.remove()
        allListener?.remove()
        listener = nil
        allListener = nil
    }

    func add(uid: String, investment: Investment) async -> String? {
        do {
            return try await InvestmentService.add(uid: uid, investment: investment)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func update(uid: String, investmentId: String, oldAmountPhp: Double, oldSourceId: String, investment: Investment) async {
        do {
            try await InvestmentService.update(uid: uid, investmentId: investmentId, oldAmountPhp: oldAmountPhp, oldSourceId: oldSourceId, investment: investment)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(uid: String, investmentId: String, sourceId: String, amountPhp: Double) async {
        do {
            try await InvestmentService.delete(uid: uid, investmentId: investmentId, sourceId: sourceId, amountPhp: amountPhp)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
