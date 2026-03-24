import Foundation
import FirebaseFirestore

struct Asset: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var category: AssetCategory
    var amount: Double
    var sourceId: String
    var sourceName: String
    var notes: String
    var year: Int
    var order: Double
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
}
