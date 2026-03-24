import SwiftUI

struct StatusBadge: View {
    let status: BuySellStatus

    var body: some View {
        Text(status.label)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(status.color)
            .glassEffect(.regular, in: .capsule)
    }
}
