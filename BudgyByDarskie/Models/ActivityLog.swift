import Foundation
import FirebaseFirestore

struct ActivityLog: Identifiable, Codable {
    @DocumentID var id: String?
    var type: ActivityLogType
    var action: ActivityLogAction
    var description: String
    var amount: Double?
    var year: Int
    @ServerTimestamp var createdAt: Date?
}

enum ActivityLogType: String, Codable, CaseIterable {
    case expense, investment, deposit, asset, buySell, receivable, wallet, transfer, savings, payment

    var label: String {
        switch self {
        case .expense: "Expense"
        case .investment: "Investment"
        case .deposit: "Deposit"
        case .asset: "Asset"
        case .buySell: "Buy & Sell"
        case .receivable: "Receivable"
        case .wallet: "Wallet"
        case .transfer: "Transfer"
        case .savings: "Savings"
        case .payment: "Payment"
        }
    }

    var icon: String {
        switch self {
        case .expense: "list.bullet.rectangle.fill"
        case .investment: "chart.line.uptrend.xyaxis"
        case .deposit: "plus.circle.fill"
        case .asset: "cube.box.fill"
        case .buySell: "arrow.left.arrow.right.circle.fill"
        case .receivable: "person.2.fill"
        case .wallet: "creditcard.fill"
        case .transfer: "arrow.right.arrow.left"
        case .savings: "banknote.fill"
        case .payment: "checkmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .expense: "red"
        case .investment: "purple"
        case .deposit: "green"
        case .asset: "cyan"
        case .buySell: "orange"
        case .receivable: "blue"
        case .wallet: "indigo"
        case .transfer: "mint"
        case .savings: "teal"
        case .payment: "green"
        }
    }
}

enum ActivityLogAction: String, Codable {
    case add, edit, delete
}
