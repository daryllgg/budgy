import Foundation
import FirebaseFirestore

struct InvestmentExit: Identifiable, Codable {
    @DocumentID var id: String?
    var investmentId: String
    var stock: String
    var investmentType: InvestmentType
    var amountInvested: Double
    var amountOut: Double
    var profit: Double
    var destinations: [FundingSource]
    var date: Date
    var notes: String
    var year: Int
    @ServerTimestamp var createdAt: Date?
}
