import SwiftUI

struct AssetRow: View {
    let asset: Asset

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: asset.category.icon)
                .font(.body)
                .foregroundStyle(asset.category.color)
                .frame(width: 36, height: 36)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(asset.name)
                    .fontWeight(.semibold)
                if !asset.sourceName.isEmpty {
                    Text(asset.sourceName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(formatPhp(asset.amount))
                .font(.system(.body, design: .rounded, weight: .bold))
                .monospacedDigit()
        }
    }
}
