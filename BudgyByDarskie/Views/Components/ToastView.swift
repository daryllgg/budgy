import SwiftUI

struct ToastView: View {
    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        if let toast = toastManager.toast {
            VStack {
                HStack(spacing: 10) {
                    Image(systemName: toast.type == .success ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(toast.type == .success ? AppTheme.positive : AppTheme.negative)
                        .font(.title3)

                    Text(toast.message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    if toast.undoAction != nil {
                        Button("Undo") {
                            hapticTap()
                            toastManager.performUndo()
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .capsule)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
