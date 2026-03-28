import Foundation
import FirebaseFirestore

struct Withdrawal: Identifiable, Codable {
    @DocumentID var id: String?
    var amount: Double
    var fee: Double
    var bankWalletId: String      // source wallet ID (kept for backward compat)
    var bankWalletName: String    // source wallet name
    var cashWalletId: String      // destination wallet ID
    var cashWalletName: String    // destination wallet name
    var date: Date
    var year: Int
    @ServerTimestamp var createdAt: Date?
}
