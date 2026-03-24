import SwiftUI

struct WalletRow: View {
    let wallet: Wallet

    private var iconColor: Color {
        wallet.type == .bank ? AppTheme.wallets : AppTheme.positive
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: wallet.type == .bank ? "building.columns.fill" : "banknote.fill")
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(wallet.name)
                    .fontWeight(.semibold)
                if !wallet.bankName.isEmpty {
                    Text(wallet.bankName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(formatPhp(wallet.balance))
                .font(.system(.body, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundColor(wallet.balance >= 0 ? .primary : .red)
        }
        .padding(.vertical, 4)
    }
}
