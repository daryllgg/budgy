import Foundation
import FirebaseFirestore

struct Expense: Identifiable, Codable {
    @DocumentID var id: String?
    var expenseDescription: String
    var amount: Double
    var date: Date
    var category: ExpenseCategory
    var sourceId: String
    var sourceName: String
    var notes: String
    var year: Int
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case expenseDescription = "description"
        case amount, date, category, sourceId, sourceName, notes, year, createdAt, updatedAt
    }
}
