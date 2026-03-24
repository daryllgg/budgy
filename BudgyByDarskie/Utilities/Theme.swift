import SwiftUI

enum AppTheme {
    // Primary accent
    static let accent = Color.blue

    // Module-specific colors
    static let dashboard = Color.blue
    static let wallets = Color.indigo
    static let expenses = Color.red
    static let investments = Color.purple

    // Secondary module colors
    static let assets = Color.orange
    static let buySell = Color.teal
    static let receivables = Color.cyan
    static let analytics = Color.purple

    // Semantic colors
    static let positive = Color.green
    static let negative = Color.red
    static let warning = Color.orange

    // Login gradient
    static func loginGradient(for scheme: ColorScheme) -> [Color] {
        scheme == .dark
            ? [Color(hex: "0A0E1A"), Color(hex: "101428")]
            : [Color(hex: "E8EDFF"), Color(hex: "F0EBFF")]
    }
}
