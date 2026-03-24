import Foundation
import FirebaseFirestore

struct Deposit: Identifiable, Codable {
    @DocumentID var id: String?
    var amount: Double
    var source: DepositSource
    var sourceLabel: String
    var walletId: String
    var walletName: String
    var date: Date
    var notes: String
    var year: Int
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
}
