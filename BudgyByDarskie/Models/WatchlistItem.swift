import Foundation
import SwiftUI
import FirebaseFirestore

struct WatchlistItem: Identifiable, Codable {
    @DocumentID var id: String?
    var symbol: String
    var name: String
    var type: WatchlistItemType
    var order: Double
    @ServerTimestamp var createdAt: Date?
}

enum WatchlistItemType: String, Codable, CaseIterable {
    case stock, crypto, etf

    var label: String {
        switch self {
        case .stock: "Stock"
        case .crypto: "Crypto"
        case .etf: "ETF"
        }
    }

    var icon: String {
        switch self {
        case .stock: "chart.bar.fill"
        case .crypto: "bitcoinsign.circle.fill"
        case .etf: "chart.line.uptrend.xyaxis"
        }
    }

    var color: Color {
        switch self {
        case .stock: .purple
        case .crypto: .orange
        case .etf: .blue
        }
    }
}

struct WatchlistQuote {
    var price: Double
    var change: Double
    var changePercent: Double
    var sparkline: [Double]
}
