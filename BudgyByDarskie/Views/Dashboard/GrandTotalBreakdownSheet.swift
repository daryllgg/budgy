import SwiftUI

struct GrandTotalBreakdownSheet: View {
    let walletTotal: Double
    let investmentTotal: Double
    let receivableTotal: Double
    let assetTotal: Double
    let grandTotal: Double

    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceManager.self) private var appearance

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    row("Wallet Balances", walletTotal)
                    row("Investments", investmentTotal)
                    row("Receivables", receivableTotal)
                    row("Assets", assetTotal)
                    HStack {
                        Text("Grand Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(appearance.maskedValue(formatPhp(grandTotal)))
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle("Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ label: String, _ amount: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(appearance.maskedValue(formatPhp(amount)))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}
