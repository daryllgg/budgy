import Foundation
import FirebaseFirestore

struct Withdrawal: Identifiable, Codable {
    @DocumentID var id: String?
    var amount: Double
    var fee: Double
    var bankWalletId: String
    var bankWalletName: String
    var cashWalletId: String
    var cashWalletName: String
    var date: Date
    var year: Int
    @ServerTimestamp var createdAt: Date?
}
