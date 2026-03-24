import SwiftUI

struct PortfolioSummaryCards: View {
    let selectedTab: InvestmentTab
    let portfolio: PortfolioSummary
    let investments: [Investment]
    let vooPrice: Double
    let vooChange: Double
    let vooChangePercent: Double
    let exchangeRate: Double

    private var totalInvestedPhp: Double {
        investments.reduce(0) { $0 + $1.amountPhp }
    }

    private var totalInvestedUsd: Double {
        investments.reduce(0) { $0 + $1.amountUsd }
    }

    private var totalQuantity: Double {
        investments.reduce(0) { $0 + $1.quantity }
    }

    private var currentValueUsd: Double {
        portfolio.totalQuantity * vooPrice
    }

    private var currentValuePhp: Double {
        currentValueUsd * exchangeRate
    }

    private var gainUsd: Double {
        currentValueUsd - portfolio.totalCostBasis
    }

    private var gainPercent: Double {
        guard portfolio.totalCostBasis > 0 else { return 0 }
        return (gainUsd / portfolio.totalCostBasis) * 100
    }

    var body: some View {
        VStack(spacing: 12) {
            // VOO Live Price — for stock tab or all tab
            if selectedTab == .stock || selectedTab == .all {
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.investments)
                                    .frame(width: 32, height: 32)
                                    .glassEffect(.regular, in: .circle)
                                VStack(alignment: .leading) {
                                    Text("VOO")
                                        .font(.headline)
                                    Text("S&P 500 ETF")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(formatUsd(vooPrice))
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .monospacedDigit()
                            HStack(spacing: 4) {
                                Image(systemName: vooChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                Text("\(formatNumber(abs(vooChange))) (\(formatNumber(abs(vooChangePercent)))%)")
                            }
                            .font(.caption)
                            .foregroundStyle(vooChange >= 0 ? AppTheme.positive : AppTheme.negative)
                        }
                    }
                }
            }

            // Summary stats
            GlassEffectContainer {
                switch selectedTab {
                case .all:
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StatCard(title: "Total Invested", value: formatPhp(totalInvestedPhp), icon: "banknote.fill", color: AppTheme.accent)
                        StatCard(title: "Invested (USD)", value: formatUsd(totalInvestedUsd), icon: "dollarsign.circle.fill", color: AppTheme.warning)
                        StatCard(title: "Current Value", value: formatPhp(currentValuePhp), icon: "chart.line.uptrend.xyaxis", color: AppTheme.positive)
                        StatCard(title: "Entries", value: "\(investments.count)", icon: "list.number", color: AppTheme.investments)
                    }

                case .stock:
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StatCard(title: "Total Invested", value: formatPhp(portfolio.totalInvestedPhp), icon: "banknote.fill", color: AppTheme.accent)
                        StatCard(title: "Current Value", value: formatPhp(currentValuePhp), icon: "chart.line.uptrend.xyaxis", color: AppTheme.positive)
                        StatCard(title: "Avg Buy Price", value: formatUsd(portfolio.averageBuyPrice), icon: "tag.fill", color: AppTheme.warning)
                        StatCard(title: "Total Shares", value: formatNumber(portfolio.totalQuantity, decimals: 4), icon: "number", color: AppTheme.investments)
                    }

                case .crypto:
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StatCard(title: "Total Invested", value: formatPhp(totalInvestedPhp), icon: "banknote.fill", color: AppTheme.accent)
                        StatCard(title: "Invested (USD)", value: formatUsd(totalInvestedUsd), icon: "dollarsign.circle.fill", color: AppTheme.warning)
                        StatCard(title: "Total Quantity", value: formatNumber(totalQuantity, decimals: 4), icon: "number", color: .orange)
                        StatCard(title: "Entries", value: "\(investments.count)", icon: "list.number", color: .orange)
                    }

                case .other:
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StatCard(title: "Total Invested", value: formatPhp(totalInvestedPhp), icon: "banknote.fill", color: AppTheme.accent)
                        StatCard(title: "Entries", value: "\(investments.count)", icon: "list.number", color: .blue)
                    }
                }
            }

            // Gain/Loss — for stock tab or all tab (when stock data exists)
            if (selectedTab == .stock || selectedTab == .all) && portfolio.totalInvestedUsd > 0 {
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Unrealized P/L")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatUsd(gainUsd))
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(gainUsd >= 0 ? AppTheme.positive : AppTheme.negative)
                            Text("\(gainUsd >= 0 ? "+" : "")\(formatNumber(gainPercent))%")
                                .font(.caption.bold())
                                .foregroundStyle(gainUsd >= 0 ? AppTheme.positive : AppTheme.negative)
                        }
                    }
                }
            }
        }
    }
}
