import Foundation
import FirebaseFirestore

@Observable
class ActivityLogViewModel {
    var logs: [ActivityLog] = []
    var isLoading = true

    private var listener: ListenerRegistration?

    var groupedByDate: [(date: String, logs: [ActivityLog])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let grouped = Dictionary(grouping: logs) { log in
            formatter.string(from: log.createdAt ?? Date())
        }
        return grouped
            .sorted { ($0.value.first?.createdAt ?? Date()) > ($1.value.first?.createdAt ?? Date()) }
            .map { (date: $0.key, logs: $0.value) }
    }

    func subscribe(uid: String) {
        listener?.remove()
        isLoading = true
        listener = ActivityLogService.subscribe(uid: uid) { [weak self] logs in
            self?.logs = logs
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
        listener = nil
    }
}
