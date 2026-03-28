import Foundation
import FirebaseFirestore

struct BuySellTransaction: Identifiable, Codable {
    @DocumentID var id: String?
    var itemName: String
    var itemType: ItemType
    var buyPrice: Double
    var sellPrice: Double?
    var profit: Double?
    var fundingSources: [FundingSource]
    var buyerName: String?
    var dateBought: Date?
    var dateSold: Date?
    var soldDestinations: [FundingSource]?
    var status: BuySellStatus
    var notes: String
    var year: Int
    var order: Double
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
}

struct FundingSource: Codable, Identifiable, Hashable {
    var id: String { sourceId }
    var sourceId: String
    var sourceName: String
    var amount: Double
}
