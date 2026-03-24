import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(NavigationManager.self) private var nav

    var body: some View {
        @Bindable var nav = nav
        TabView(selection: $nav.selectedTab) {
            Tab("Dashboard", systemImage: "square.grid.2x2.fill", value: 0) {
                DashboardView()
            }

            Tab("Finance", systemImage: "banknote.fill", value: 1) {
                FinanceView()
            }

            Tab("Investments", systemImage: "chart.line.uptrend.xyaxis", value: 2) {
                InvestmentsView()
            }

            Tab("More", systemImage: "ellipsis.circle.fill", value: 3) {
                MoreMenuView()
            }
        }
        .tint(AppTheme.accent)
        .environment(authVM)
    }
}

struct MoreMenuView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(NavigationManager.self) private var nav
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 14) {
                    NetworkStatusLabel()

                    GlassEffectContainer {
                        VStack(spacing: 12) {
                            MoreMenuItem(icon: "cube.box.fill", color: AppTheme.assets, title: "Assets", subtitle: "Track your gadgets & belongings") {
                                AssetsView()
                            }
                            MoreMenuItem(icon: "arrow.left.arrow.right.circle.fill", color: AppTheme.buySell, title: "Buy & Sell", subtitle: "Flip items for profit") {
                                BuySellView()
                            }
                            MoreMenuItem(icon: "person.2.fill", color: AppTheme.receivables, title: "Receivables", subtitle: "Money owed to you") {
                                ReceivablesView()
                            }
                            MoreMenuItem(icon: "chart.bar.fill", color: AppTheme.analytics, title: "Analytics", subtitle: "Charts & insights") {
                                AnalyticsView()
                            }
                            MoreMenuItem(icon: "list.bullet.clipboard.fill", color: .mint, title: "Activity Log", subtitle: "All your transactions & actions") {
                                ActivityLogView()
                            }
                            MoreMenuItem(icon: "gearshape.fill", color: .gray, title: "Settings", subtitle: "Appearance, profile & more") {
                                SettingsView()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("More")
            .navigationDestination(for: MoreDestination.self) { dest in
                switch dest {
                case .assets: AssetsView()
                case .buySell: BuySellView()
                case .receivables: ReceivablesView()
                case .analytics: AnalyticsView()
                case .settings: SettingsView()
                }
            }
        }
        .onChange(of: nav.moreDestination) { _, dest in
            if let dest {
                path.append(dest)
                nav.moreDestination = nil
            }
        }
    }
}

struct MoreMenuItem<Destination: View>: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.semibold)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .contentShape(Rectangle())
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
