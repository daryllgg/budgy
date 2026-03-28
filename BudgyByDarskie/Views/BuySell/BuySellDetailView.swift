import SwiftUI

struct BuySellDetailView: View {
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
        List {
            // Header
            Section {
                HStack(spacing: 14) {
                    Image(systemName: typeIcon)
                        .font(.title2)
                        .foregroundStyle(transaction.itemType.color)
                        .frame(width: 48, height: 48)
                        .glassEffect(.regular, in: .circle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.itemName)
                            .font(.title3.bold())
                        HStack(spacing: 8) {
                            StatusBadge(status: transaction.status)
                            Text(transaction.itemType.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Pricing
            Section("Pricing") {
                LabeledContent("Buy Price", value: formatPhp(transaction.buyPrice))
                if let sellPrice = transaction.sellPrice {
                    LabeledContent("Sell Price", value: formatPhp(sellPrice))
                }
                if let profit = transaction.profit {
                    HStack {
                        Text("Profit")
                        Spacer()
                        Text(formatPhp(profit))
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundStyle(profit >= 0 ? AppTheme.positive : AppTheme.negative)
                    }
                }
            }

            // Dates
            Section("Dates") {
                if let dateBought = transaction.dateBought {
                    LabeledContent("Date Bought", value: dateBought.formatted(date: .abbreviated, time: .omitted))
                }
                if let dateSold = transaction.dateSold {
                    LabeledContent("Date Sold", value: dateSold.formatted(date: .abbreviated, time: .omitted))
                }
            }

            // Buyer
            if let buyer = transaction.buyerName, !buyer.isEmpty {
                Section("Buyer") {
                    LabeledContent("Name", value: buyer)
                }
            }

            // Funding Sources
            if !transaction.fundingSources.isEmpty {
                Section("Funding Sources (Where you paid from)") {
                    ForEach(transaction.fundingSources) { src in
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundStyle(.red.opacity(0.7))
                            Text(src.sourceName)
                            Spacer()
                            Text(formatPhp(src.amount))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Sold Destinations
            if let destinations = transaction.soldDestinations, !destinations.isEmpty {
                Section("Sold To (Where money went)") {
                    ForEach(destinations) { dest in
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(.green.opacity(0.7))
                            Text(dest.sourceName)
                            Spacer()
                            Text(formatPhp(dest.amount))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Notes
            if !transaction.notes.isEmpty {
                Section("Notes") {
                    Text(transaction.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
