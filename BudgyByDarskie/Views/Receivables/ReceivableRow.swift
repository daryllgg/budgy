import SwiftUI

struct ReceivableRow: View {
    let receivable: Receivable
    var showName: Bool = true

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if showName {
                    Text(receivable.name)
                        .fontWeight(.medium)
                }
                if !receivable.receivableDescription.isEmpty {
                    Text(receivable.receivableDescription)
                        .fontWeight(showName ? .regular : .medium)
                        .font(showName ? .caption : .body)
                        .foregroundStyle(showName ? .secondary : .primary)
                }
                HStack(spacing: 8) {
                    if let createdAt = receivable.createdAt {
                        Text(createdAt.formattedMMMddyyyy())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if receivable.isReimbursement {
                        Text("Reimbursement")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(.blue)
                            .glassEffect(.regular, in: .capsule)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatPhp(receivable.remaining))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(receivable.remaining > 0 ? .orange : .green)
                Text(formatPhp(receivable.amount))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }
}
