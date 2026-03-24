import Foundation
import FirebaseFirestore

struct ProfitAllocation: Identifiable, Codable {
    @DocumentID var id: String?
    var label: String
    var destType: String
    var amount: Double
    var year: Int
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
}
