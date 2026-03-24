import SwiftUI

enum ToastType {
    case success
    case error
}

struct Toast: Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let undoAction: (() async -> Void)?

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
class ToastManager {
    var toast: Toast?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, type: ToastType = .success, undoAction: (() async -> Void)? = nil) {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.3)) {
            toast = Toast(message: message, type: type, undoAction: undoAction)
        }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.3)) {
            toast = nil
        }
    }

    func performUndo() {
        guard let action = toast?.undoAction else { return }
        dismiss()
        Task {
            await action()
        }
    }
}
