import Foundation
import Network

@Observable
class NetworkMonitor {
    var isConnected = true
    var showSyncedMessage = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var wasDisconnected = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self else { return }
                let connected = path.status == .satisfied

                if !connected {
                    self.wasDisconnected = true
                    self.showSyncedMessage = false
                }

                if connected && self.wasDisconnected {
                    self.wasDisconnected = false
                    // Brief delay so Firestore can flush pending writes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.showSyncedMessage = true
                        // Auto-dismiss after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.showSyncedMessage = false
                        }
                    }
                }

                self.isConnected = connected
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
