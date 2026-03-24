import SwiftUI

enum MoreDestination: Hashable {
    case assets
    case buySell
    case receivables
    case analytics
    case settings
}

@Observable
class NavigationManager {
    var selectedTab: Int = 0
    var financeSegment: Int = 0 // 0 = Wallets, 1 = Expenses
    var moreDestination: MoreDestination?
    var showQuickAddExpense: Bool = false

    func navigateToWallets() {
        selectedTab = 1
        financeSegment = 0
    }

    func navigateToExpenses() {
        selectedTab = 1
        financeSegment = 1
    }

    func navigateToInvestments() {
        selectedTab = 2
    }

    func navigateToBuySell() {
        selectedTab = 3
        moreDestination = .buySell
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "budgy" else { return }
        switch url.host {
        case "add-expense":
            selectedTab = 1
            financeSegment = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showQuickAddExpense = true
            }
        case "dashboard":
            selectedTab = 0
        default:
            break
        }
    }
}
