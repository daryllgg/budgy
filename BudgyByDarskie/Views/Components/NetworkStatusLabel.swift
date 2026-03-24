import SwiftUI

struct NetworkStatusLabel: View {
    @Environment(NetworkMonitor.self) private var network

    var body: some View {
        if !network.isConnected {
            HStack(spacing: 6) {
                Image(systemName: "wifi.slash")
                    .font(.caption2)
                Text("You're offline")
                    .font(.caption.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.red, in: Capsule())
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: network.isConnected)
        } else if network.showSyncedMessage {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.icloud")
                    .font(.caption2)
                Text("All synced!")
                    .font(.caption.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.green, in: Capsule())
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: network.showSyncedMessage)
        }
    }
}
