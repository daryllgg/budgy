import Foundation
import FirebaseFirestore

struct Investment: Identifiable, Codable {
    @DocumentID var id: String?
    var date: Date
    var investmentType: InvestmentType
    var source: InvestmentSource
    var sourceId: String
    var sourceName: String
    var stock: String
    var amountPhp: Double
    var amountUsd: Double
    var buyPrice: Double
    var quantity: Double
    var remarks: String
    var exited: Bool?
    var year: Int
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
}

struct PortfolioSummary {
    var totalInvestedPhp: Double = 0
    var totalInvestedUsd: Double = 0
    var totalCostBasis: Double = 0
    var averageBuyPrice: Double = 0
    var totalQuantity: Double = 0
}

struct StockQuote {
    var price: Double
    var change: Double
    var changePercent: Double
}
