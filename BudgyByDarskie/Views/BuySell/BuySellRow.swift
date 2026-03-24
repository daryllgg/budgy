import SwiftUI

struct BuySellRow: View {
    let transaction: BuySellTransaction

    private var typeIcon: String {
        switch transaction.itemType {
        case .phone: return "iphone"
        case .laptop: return "laptopcomputer"
        case .tablet: return "ipad"
        case .accessory, .other: return "tag.fill"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: typeIcon)
                .font(.body)
                .foregroundStyle(transaction.itemType.color)
                .frame(width: 36, height: 36)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.itemName)
                    .fontWeight(.semibold)
                HStack(spacing: 6) {
                    StatusBadge(status: transaction.status)
                    if let buyer = transaction.buyerName, !buyer.isEmpty {
                        Text(buyer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                if let profit = transaction.profit {
                    Text(formatPhp(profit))
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(profit >= 0 ? AppTheme.positive : AppTheme.negative)
                }
                if transaction.buyPrice > 0 {
                    Text("Cost: \(formatPhp(transaction.buyPrice))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 2)
    }
}
