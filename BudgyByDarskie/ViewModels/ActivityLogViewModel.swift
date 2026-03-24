import SwiftUI
import FirebaseFirestore

@Observable
class ActivityLogViewModel {
    var recentLogs: [ActivityLog] = []
    var olderLogs: [ActivityLog] = []
    var isLoading = true
    var isLoadingMore = false
    var hasMoreData = true

    private var listener: ListenerRegistration?
    private var lastDocument: DocumentSnapshot?
    private var sinceDate: Date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!

    var logs: [ActivityLog] {
        let allIds = Set(recentLogs.compactMap(\.id))
        let dedupedOlder = olderLogs.filter { log in
            guard let id = log.id else { return true }
            return !allIds.contains(id)
        }
        return (recentLogs + dedupedOlder).sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

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
        olderLogs = []
        lastDocument = nil
        hasMoreData = true
        sinceDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!

        listener = ActivityLogService.subscribeRecent(uid: uid, since: sinceDate) { [weak self] logs in
            guard let self else { return }
            withAnimation {
                self.recentLogs = logs
                self.isLoading = false
            }
        }
    }

    func loadMore(uid: String) async {
        guard !isLoadingMore, hasMoreData else { return }
        isLoadingMore = true

        do {
            let result = try await ActivityLogService.fetchOlderPage(
                uid: uid,
                before: sinceDate,
                lastDocument: lastDocument,
                limit: 20
            )
            withAnimation {
                olderLogs.append(contentsOf: result.logs)
                lastDocument = result.lastDoc
                if result.logs.count < 20 {
                    hasMoreData = false
                }
                isLoadingMore = false
            }
        } catch {
            isLoadingMore = false
        }
    }

    func unsubscribe() {
        listener?.remove()
        listener = nil
    }
}
