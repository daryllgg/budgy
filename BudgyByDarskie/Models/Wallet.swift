import Foundation
import FirebaseFirestore

struct Wallet: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var type: WalletType
    var bankName: String
    var balance: Double
    var notes: String
    var year: Int
    var order: Double
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
}
