import Foundation
import FirebaseFirestore

struct SavingsBreakdown: Identifiable, Codable {
    @DocumentID var id: String?
    var label: String
    var amount: Double
    var year: Int
    @ServerTimestamp var updatedAt: Date?
}
