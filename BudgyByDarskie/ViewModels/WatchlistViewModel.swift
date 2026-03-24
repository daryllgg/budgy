import Foundation
import FirebaseFirestore

@Observable
class WatchlistViewModel {
    var items: [WatchlistItem] = []
    var prices: [String: WatchlistQuote] = [:]
    var isLoading = true
    var isFetchingPrices = false

    private var listener: ListenerRegistration?

    func subscribe(uid: String) {
        listener?.remove()
        isLoading = true
        listener = WatchlistService.subscribe(uid: uid) { [weak self] items in
            self?.items = items
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
        listener = nil
    }

    func add(uid: String, item: WatchlistItem) async -> String? {
        do {
            return try await WatchlistService.add(uid: uid, item: item)
        } catch {
            return nil
        }
    }

    func delete(uid: String, itemId: String) async {
        let symbol = items.first(where: { $0.id == itemId })?.symbol ?? ""
        try? await WatchlistService.delete(uid: uid, itemId: itemId)
        prices.removeValue(forKey: symbol)
    }

    func fetchAllPrices() async {
        isFetchingPrices = true

        await withTaskGroup(of: (String, WatchlistQuote?).self) { group in
            for item in items {
                group.addTask {
                    let quote = await self.fetchQuote(symbol: item.symbol)
                    return (item.symbol, quote)
                }
            }

            for await (symbol, quote) in group {
                if let quote {
                    prices[symbol] = quote
                }
            }
        }

        isFetchingPrices = false
    }

    private func fetchQuote(symbol: String) async -> WatchlistQuote? {
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?range=1mo&interval=1d"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if let chart = json?["chart"] as? [String: Any],
               let results = chart["result"] as? [[String: Any]],
               let result = results.first,
               let meta = result["meta"] as? [String: Any],
               let price = meta["regularMarketPrice"] as? Double,
               let prevClose = meta["chartPreviousClose"] as? Double,
               let indicators = result["indicators"] as? [String: Any],
               let quote = indicators["quote"] as? [[String: Any]],
               let firstQuote = quote.first,
               let closes = firstQuote["close"] as? [Any] {

                let change = price - prevClose
                let changePercent = prevClose > 0 ? (change / prevClose) * 100 : 0
                let sparkline = closes.compactMap { $0 as? Double }

                return WatchlistQuote(
                    price: price,
                    change: change,
                    changePercent: changePercent,
                    sparkline: sparkline
                )
            }
        } catch { }
        return nil
    }
}
