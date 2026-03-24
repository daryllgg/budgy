import SwiftUI

// MARK: - Wallet Type
enum WalletType: String, Codable, CaseIterable {
    case bank, cash
    var label: String {
        switch self {
        case .bank: "Bank"
        case .cash: "Cash"
        }
    }
}

// MARK: - Expense Category
enum ExpenseCategory: String, Codable, CaseIterable {
    case food, transport, utilities, shopping, entertainment, health, other
    var label: String {
        switch self {
        case .food: "Food"
        case .transport: "Transport"
        case .utilities: "Utilities"
        case .shopping: "Shopping"
        case .entertainment: "Entertainment"
        case .health: "Health"
        case .other: "Other"
        }
    }
    var color: Color {
        switch self {
        case .food: .orange
        case .transport: .blue
        case .utilities: .yellow
        case .shopping: .pink
        case .entertainment: .purple
        case .health: .red
        case .other: .gray
        }
    }
    var icon: String {
        switch self {
        case .food: "fork.knife"
        case .transport: "car"
        case .utilities: "bolt"
        case .shopping: "bag"
        case .entertainment: "gamecontroller"
        case .health: "heart"
        case .other: "ellipsis.circle"
        }
    }
}

// MARK: - Investment Type
enum InvestmentType: String, Codable, CaseIterable {
    case stock, crypto, other
    var label: String {
        switch self {
        case .stock: "Stock"
        case .crypto: "Crypto"
        case .other: "Other"
        }
    }
    var color: Color {
        switch self {
        case .stock: .purple
        case .crypto: .orange
        case .other: .blue
        }
    }
}

// MARK: - Investment Source
enum InvestmentSource: String, Codable, CaseIterable {
    case salary, buySellProfits, oldSavings
    var label: String {
        switch self {
        case .salary: "Salary"
        case .buySellProfits: "Buy & Sell Profits"
        case .oldSavings: "Old Savings"
        }
    }
}

// MARK: - Asset Category
enum AssetCategory: String, Codable, CaseIterable {
    case cellphone, laptop, tablet, accessory, other
    var label: String {
        switch self {
        case .cellphone: "Cellphone"
        case .laptop: "Laptop"
        case .tablet: "Tablet"
        case .accessory: "Accessory"
        case .other: "Other"
        }
    }
    var icon: String {
        switch self {
        case .cellphone: "iphone"
        case .laptop: "laptopcomputer"
        case .tablet: "ipad"
        case .accessory: "applewatch"
        case .other: "ellipsis.circle"
        }
    }
    var color: Color {
        switch self {
        case .cellphone: .blue
        case .laptop: .purple
        case .tablet: .green
        case .accessory: .orange
        case .other: .gray
        }
    }
}

// MARK: - Item Type (Buy & Sell)
enum ItemType: String, Codable, CaseIterable {
    case phone, laptop, tablet, accessory, other
    var label: String {
        switch self {
        case .phone: "Phone"
        case .laptop: "Laptop"
        case .tablet: "Tablet"
        case .accessory: "Accessory"
        case .other: "Other"
        }
    }
    var color: Color {
        switch self {
        case .phone: .purple
        case .laptop: .blue
        case .tablet: .green
        case .accessory: .orange
        case .other: .gray
        }
    }
}

// MARK: - Buy & Sell Status
enum BuySellStatus: String, Codable, CaseIterable {
    case available, pending, sold
    var label: String {
        switch self {
        case .available: "Available"
        case .pending: "Pending"
        case .sold: "Sold"
        }
    }
    var color: Color {
        switch self {
        case .available: .blue
        case .pending: .orange
        case .sold: .green
        }
    }
}

// MARK: - Deposit Source
enum DepositSource: String, Codable, CaseIterable {
    case salary, milestone, buySellProfit, oldSavings, other
    var label: String {
        switch self {
        case .salary: "Salary"
        case .milestone: "Milestone"
        case .buySellProfit: "Buy & Sell Profit"
        case .oldSavings: "Old Savings"
        case .other: "Other"
        }
    }
}
