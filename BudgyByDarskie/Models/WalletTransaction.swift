import Foundation

enum WalletTransactionType: String {
    case deposit
    case expense
    case withdrawal       // bank side: money out + fee
    case withdrawalIn     // cash side: money received
    case investment
    case investmentExit     // money in: TP/SL proceeds
    case buySell
    case buySellIn          // money in: sold item proceeds
    case receivablePayment
    case receivable         // money out: lent to someone
    case asset

    var label: String {
        switch self {
        case .deposit: "Deposit"
        case .expense: "Expense"
        case .withdrawal: "Transfer Out"
        case .withdrawalIn: "Transfer In"
        case .investment: "Investment"
        case .investmentExit: "TP/SL"
        case .buySell: "Buy & Sell"
        case .buySellIn: "Buy & Sell (Sold)"
        case .receivablePayment: "Receivable Payment"
        case .receivable: "Receivable"
        case .asset: "Asset"
        }
    }

    var icon: String {
        switch self {
        case .deposit: "arrow.down.circle.fill"
        case .expense: "arrow.up.circle.fill"
        case .withdrawal: "arrow.left.arrow.right.circle.fill"
        case .withdrawalIn: "arrow.down.circle.fill"
        case .investment: "chart.line.uptrend.xyaxis.circle.fill"
        case .investmentExit: "arrow.down.circle.fill"
        case .buySell: "arrow.triangle.2.circlepath.circle.fill"
        case .buySellIn: "arrow.down.circle.fill"
        case .receivablePayment: "arrow.down.circle.fill"
        case .receivable: "person.fill"
        case .asset: "cube.fill"
        }
    }

    var isInflow: Bool {
        switch self {
        case .deposit, .withdrawalIn, .receivablePayment, .buySellIn, .investmentExit: true
        case .expense, .withdrawal, .investment, .buySell, .receivable, .asset: false
        }
    }
}

struct WalletTransaction: Identifiable {
    let id: String
    let type: WalletTransactionType
    let title: String
    let subtitle: String
    let amount: Double
    let date: Date
    let notes: String
}
