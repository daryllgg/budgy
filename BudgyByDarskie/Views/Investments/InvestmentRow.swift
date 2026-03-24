import SwiftUI

struct InvestmentRow: View {
    let investment: Investment

    private var typeIcon: String {
        switch investment.investmentType {
        case .stock: return "chart.line.uptrend.xyaxis"
        case .crypto: return "bitcoinsign.circle.fill"
        case .other: return "dollarsign.circle.fill"
        }
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: typeIcon)
                    .font(.body)
                    .foregroundStyle(investment.investmentType.color)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: .circle)

                VStack(alignment: .leading, spacing: 3) {
                    Text(investment.stock)
                        .font(.system(.body, design: .rounded, weight: .bold))
                    Text(investment.date.formattedMMMddyyyy())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !investment.remarks.isEmpty {
                        Text(investment.remarks)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(formatPhp(investment.amountPhp))
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    if investment.amountUsd > 0 {
                        Text(formatUsd(investment.amountUsd))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    if investment.quantity > 0 {
                        Text("\(formatNumber(investment.quantity, decimals: 4)) shares")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
