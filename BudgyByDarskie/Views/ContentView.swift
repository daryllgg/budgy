import SwiftUI

struct ContentView: View {
    @State private var authVM = AuthViewModel()
    @State private var showSplash = true
    @Environment(NavigationManager.self) private var nav
    @State private var pendingURL: URL?

    var body: some View {
        ZStack {
            Group {
                if showSplash {
                    SplashView()
                } else if authVM.isAuthenticated {
                    MainTabView()
                        .environment(authVM)
                } else {
                    LoginView()
                        .environment(authVM)
                }
            }

            ToastView()
        }
        .tint(AppTheme.accent)
        .onOpenURL { url in
            if url.scheme == "budgy" {
                if showSplash {
                    pendingURL = url
                } else {
                    nav.handleDeepLink(url)
                }
            } else {
                _ = BudgyByDarskieApp.handleOpenURL(url)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            while authVM.isLoading {
                try? await Task.sleep(for: .milliseconds(50))
            }
            withAnimation(.easeOut(duration: 0.3)) {
                showSplash = false
            }
            // Handle pending deep link or App Intent after views are loaded
            try? await Task.sleep(for: .milliseconds(600))
            if let url = pendingURL {
                pendingURL = nil
                nav.handleDeepLink(url)
            } else if AddExpenseIntent.pendingAction {
                AddExpenseIntent.pendingAction = false
                triggerQuickExpense()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            guard !showSplash, authVM.isAuthenticated else { return }
            if AddExpenseIntent.pendingAction {
                AddExpenseIntent.pendingAction = false
                triggerQuickExpense()
            }
        }
    }

    private func triggerQuickExpense() {
        nav.selectedTab = 1
        nav.financeSegment = 1
        // Delay so the Finance tab and Expenses segment load first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            nav.showQuickAddExpense = true
        }
    }
}
