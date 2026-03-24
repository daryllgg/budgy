import Foundation

@Observable
class StockPriceViewModel {
    var vooPrice: Double = 0
    var vooChange: Double = 0
    var vooChangePercent: Double = 0
    var isLoading = false
    var errorMessage: String?

    func fetchVOOPrice() async {
        isLoading = true
        errorMessage = nil

        do {
            // Using Yahoo Finance API
            let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/VOO?interval=1d&range=1d"
            guard let url = URL(string: urlString) else { return }

            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if let chart = json?["chart"] as? [String: Any],
               let results = chart["result"] as? [[String: Any]],
               let result = results.first,
               let meta = result["meta"] as? [String: Any],
               let price = meta["regularMarketPrice"] as? Double,
               let prevClose = meta["chartPreviousClose"] as? Double {
                vooPrice = price
                vooChange = price - prevClose
                vooChangePercent = (vooChange / prevClose) * 100
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
