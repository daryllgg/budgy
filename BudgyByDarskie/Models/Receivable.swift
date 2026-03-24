import Foundation
import FirebaseFirestore

struct Receivable: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var receivableDescription: String
    var amount: Double
    var sourceId: String
    var sourceName: String
    var isReimbursement: Bool
    var notes: String
    var year: Int
    var order: Double
    var totalPaid: Double?
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    var remaining: Double { amount - (totalPaid ?? 0) }
    var isFullyPaid: Bool { remaining <= 0 }

    enum CodingKeys: String, CodingKey {
        case id, name
        case receivableDescription = "description"
        case amount, sourceId, sourceName, isReimbursement, notes, year, order, totalPaid, createdAt, updatedAt
    }
}

struct ReceivablePayment: Identifiable, Codable {
    @DocumentID var id: String?
    var amount: Double
    var date: Date
    var destinations: [PaymentDestination]
    var notes: String
    @ServerTimestamp var createdAt: Date?
}

struct PaymentDestination: Codable, Identifiable, Hashable {
    var id: String { walletId }
    var walletId: String
    var walletName: String
    var amount: Double
}
