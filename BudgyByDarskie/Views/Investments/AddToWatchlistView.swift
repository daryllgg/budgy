import SwiftUI

struct AddToWatchlistView: View {
    let existingSymbols: [String]
    let onAdd: (WatchlistItem) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var symbol = ""
    @State private var name = ""
    @State private var type: WatchlistItemType = .stock
    @State private var isSaving = false

    private let presets: [(symbol: String, name: String, type: WatchlistItemType)] = [
        ("VOO", "Vanguard S&P 500 ETF", .etf),
        ("QQQ", "Invesco QQQ Trust", .etf),
        ("SPY", "SPDR S&P 500 ETF", .etf),
        ("AAPL", "Apple Inc.", .stock),
        ("MSFT", "Microsoft Corp.", .stock),
        ("GOOGL", "Alphabet Inc.", .stock),
        ("TSLA", "Tesla Inc.", .stock),
        ("NVDA", "NVIDIA Corp.", .stock),
        ("AMZN", "Amazon.com Inc.", .stock),
        ("META", "Meta Platforms Inc.", .stock),
        ("BTC-USD", "Bitcoin", .crypto),
        ("ETH-USD", "Ethereum", .crypto),
        ("SOL-USD", "Solana", .crypto),
        ("DOGE-USD", "Dogecoin", .crypto),
        ("XRP-USD", "XRP", .crypto),
        ("ADA-USD", "Cardano", .crypto),
    ]

    private var filteredPresets: [(symbol: String, name: String, type: WatchlistItemType)] {
        let available = presets.filter { !existingSymbols.contains($0.symbol) }
        if symbol.isEmpty { return available }
        return available.filter {
            $0.symbol.localizedCaseInsensitiveContains(symbol) ||
            $0.name.localizedCaseInsensitiveContains(symbol)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Custom Symbol") {
                    TextField("Symbol (e.g., AAPL, BTC-USD)", text: $symbol)
                        .textInputAutocapitalization(.characters)
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(WatchlistItemType.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                }

                if !filteredPresets.isEmpty {
                    Section("Quick Add") {
                        ForEach(filteredPresets, id: \.symbol) { preset in
                            Button {
                                addPreset(preset)
                            } label: {
                                HStack {
                                    Image(systemName: preset.type.icon)
                                        .foregroundStyle(preset.type.color)
                                        .frame(width: 28)
                                    VStack(alignment: .leading) {
                                        Text(preset.symbol).fontWeight(.semibold)
                                        Text(preset.name).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isSaving)
                        }
                    }
                }
            }
            .navigationTitle("Add to Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addCustom() }
                        .disabled(symbol.isEmpty || name.isEmpty || isSaving)
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func addCustom() {
        isSaving = true
        let item = WatchlistItem(
            symbol: symbol.uppercased(),
            name: name,
            type: type,
            order: 0
        )
        Task {
            await onAdd(item)
            dismiss()
        }
    }

    private func addPreset(_ preset: (symbol: String, name: String, type: WatchlistItemType)) {
        isSaving = true
        let item = WatchlistItem(
            symbol: preset.symbol,
            name: preset.name,
            type: preset.type,
            order: 0
        )
        Task {
            await onAdd(item)
            isSaving = false
        }
    }
}
