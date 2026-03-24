import SwiftUI
import Charts

struct WatchlistView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(ToastManager.self) private var toast
    @State private var watchlistVM = WatchlistViewModel()
    @State private var showAddSheet = false
    @State private var deleteTarget: WatchlistItem?

    var body: some View {
        Group {
            if watchlistVM.isLoading {
                ProgressView()
            } else if watchlistVM.items.isEmpty {
                EmptyStateView(
                    icon: "star.circle",
                    title: "No Watchlist Items",
                    message: "Add stocks or crypto to your watchlist"
                )
            } else {
                List {
                    ForEach(watchlistVM.items) { item in
                        WatchlistRow(
                            item: item,
                            quote: watchlistVM.prices[item.symbol]
                        )
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { deleteTarget = item } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Watchlist")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddToWatchlistView(existingSymbols: watchlistVM.items.map(\.symbol)) { item in
                guard let uid = authVM.uid else { return }
                let docId = await watchlistVM.add(uid: uid, item: item)
                if docId != nil {
                    hapticSuccess()
                    toast.show("\(item.symbol) added to watchlist")
                    Task { await watchlistVM.fetchAllPrices() }
                }
            }
        }
        .alert("Remove from Watchlist?", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        ), presenting: deleteTarget) { item in
            Button("Remove", role: .destructive) {
                guard let uid = authVM.uid, let id = item.id else { return }
                Task {
                    await watchlistVM.delete(uid: uid, itemId: id)
                    hapticSuccess()
                    toast.show("\(item.symbol) removed")
                }
            }
        } message: { item in
            Text("Remove \(item.symbol) from your watchlist?")
        }
        .refreshable {
            await watchlistVM.fetchAllPrices()
        }
        .onAppear {
            guard let uid = authVM.uid else { return }
            watchlistVM.subscribe(uid: uid)
            Task { await watchlistVM.fetchAllPrices() }
        }
        .onDisappear { watchlistVM.unsubscribe() }
    }
}

struct WatchlistRow: View {
    let item: WatchlistItem
    let quote: WatchlistQuote?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.icon)
                .font(.title3)
                .foregroundStyle(item.type.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.symbol)
                    .font(.headline)
                Text(item.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let quote, !quote.sparkline.isEmpty {
                Chart {
                    ForEach(Array(quote.sparkline.enumerated()), id: \.offset) { idx, value in
                        LineMark(
                            x: .value("Day", idx),
                            y: .value("Price", value)
                        )
                        .foregroundStyle(quote.change >= 0 ? Color.green : Color.red)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(width: 60, height: 30)
            }

            if let quote {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatUsd(quote.price))
                        .font(.subheadline.bold())
                        .monospacedDigit()
                    HStack(spacing: 2) {
                        Image(systemName: quote.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(formatNumber(abs(quote.changePercent)))%")
                    }
                    .font(.caption)
                    .foregroundStyle(quote.change >= 0 ? AppTheme.positive : AppTheme.negative)
                }
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}
