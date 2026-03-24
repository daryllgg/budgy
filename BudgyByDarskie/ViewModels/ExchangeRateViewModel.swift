import Foundation

@Observable
class ExchangeRateViewModel {
    var phpToUsd: Double = 0
    var usdToPhp: Double = 0
    var isLoading = false
    var errorMessage: String?

    func fetchRate() async {
        isLoading = true
        errorMessage = nil

        do {
            let urlString = "https://api.exchangerate-api.com/v4/latest/USD"
            guard let url = URL(string: urlString) else { return }

            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if let rates = json?["rates"] as? [String: Double],
               let php = rates["PHP"] {
                usdToPhp = php
                phpToUsd = 1.0 / php
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func convertToUsd(_ php: Double) -> Double {
        guard usdToPhp > 0 else { return 0 }
        return php / usdToPhp
    }

    func convertToPhp(_ usd: Double) -> Double {
        return usd * usdToPhp
    }
}
