import SwiftUI

struct CurrencyText: View {
    let amount: Double
    var currency: Currency = .php
    var style: Font = .body

    enum Currency {
        case php, usd
    }

    var body: some View {
        Text(currency == .php ? formatPhp(amount) : formatUsd(amount))
            .font(style)
            .monospacedDigit()
    }
}
