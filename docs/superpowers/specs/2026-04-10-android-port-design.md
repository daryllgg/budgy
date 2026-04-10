# BudgyByDarskie Android — Design Spec

## Overview

Port the existing BudgyByDarskie iOS finance tracking app to Android with full feature parity. The Android app shares the same Firebase backend (Firestore + Auth), so users see the same data on both platforms. The UI follows Material Design 3 conventions to feel native on Android.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Language | Kotlin | Standard for modern Android development |
| UI Framework | Jetpack Compose | Declarative UI, direct equivalent to SwiftUI |
| Architecture | MVVM (ViewModel + StateFlow + Repository) | Maps cleanly to iOS MVVM pattern |
| DI | Hilt | Standard Android DI, integrates with ViewModel |
| Navigation | Jetpack Navigation Compose | Type-safe navigation, deep link support |
| Async | Kotlin Coroutines + Flow | Equivalent to Swift async/await + Combine |
| Backend | Same Firebase project | Shared data across iOS and Android |
| Charts | Vico | Compose-native charting library |
| OCR | Google ML Kit | Receipt scanning, same accuracy as iOS Vision |
| Notifications | WorkManager | Reliable background scheduling for reminders |
| Min SDK | 26 (Android 8.0) | Covers 95%+ of active devices |
| Design System | Material Design 3 | Native Android look and feel |

## Project Location

Separate repository at `/Users/daryll/Desktop/BudgyByDarskieAndroid/`

Package name: `com.darskie.budgybydarskie`

## Architecture

```
app/src/main/java/com/darskie/budgybydarskie/
├── BudgyApp.kt                    # Application class (Hilt entry point)
├── MainActivity.kt                # Single activity, Compose host
├── data/
│   ├── model/                     # 17 data classes mirroring iOS models
│   │   ├── Expense.kt
│   │   ├── Wallet.kt
│   │   ├── Deposit.kt
│   │   ├── Withdrawal.kt
│   │   ├── Investment.kt
│   │   ├── InvestmentExit.kt
│   │   ├── BuySellTransaction.kt
│   │   ├── Asset.kt
│   │   ├── Receivable.kt
│   │   ├── ReceivablePayment.kt
│   │   ├── WalletTransaction.kt
│   │   ├── ActivityLog.kt
│   │   ├── ProfitAllocation.kt
│   │   ├── SavingsBreakdown.kt
│   │   ├── WatchlistItem.kt
│   │   ├── WatchlistQuote.kt
│   │   └── PortfolioSummary.kt
│   └── repository/                # 13 repositories wrapping Firestore
│       ├── AuthRepository.kt
│       ├── ExpenseRepository.kt
│       ├── WalletRepository.kt
│       ├── DepositRepository.kt
│       ├── InvestmentRepository.kt
│       ├── BuySellRepository.kt
│       ├── ReceivableRepository.kt
│       ├── ReceivablePaymentRepository.kt
│       ├── AssetRepository.kt
│       ├── WalletTransactionRepository.kt
│       ├── ActivityLogRepository.kt
│       ├── WatchlistRepository.kt
│       ├── ProfitAllocationRepository.kt
│       └── SavingsRepository.kt
├── di/
│   ├── AppModule.kt               # Firebase instances, singletons
│   └── RepositoryModule.kt        # Repository bindings
├── ui/
│   ├── auth/
│   │   ├── LoginScreen.kt
│   │   └── AuthViewModel.kt
│   ├── dashboard/
│   │   ├── DashboardScreen.kt
│   │   ├── DashboardViewModel.kt
│   │   ├── GrandTotalSheet.kt
│   │   └── QuickExpenseSheet.kt
│   ├── finance/
│   │   ├── FinanceScreen.kt       # Segmented: Wallets | Expenses
│   │   ├── wallets/
│   │   │   ├── WalletsSection.kt
│   │   │   ├── WalletViewModel.kt
│   │   │   ├── WalletFormSheet.kt
│   │   │   ├── DepositFormSheet.kt
│   │   │   ├── TransferFormSheet.kt
│   │   │   └── WalletTransactionHistoryScreen.kt
│   │   └── expenses/
│   │       ├── ExpensesSection.kt
│   │       ├── ExpenseViewModel.kt
│   │       ├── ExpenseFormSheet.kt
│   │       ├── ExpenseDetailSheet.kt
│   │       ├── ExpenseExportSheet.kt
│   │       ├── ReceiptScannerScreen.kt
│   │       └── ExpenseRow.kt
│   ├── investments/
│   │   ├── InvestmentsScreen.kt
│   │   ├── InvestmentViewModel.kt
│   │   ├── InvestmentFormSheet.kt
│   │   ├── TPSLFormSheet.kt
│   │   ├── PortfolioSummaryCards.kt
│   │   ├── WatchlistScreen.kt
│   │   └── AddToWatchlistSheet.kt
│   ├── buysell/
│   │   ├── BuySellScreen.kt
│   │   ├── BuySellViewModel.kt
│   │   ├── BuySellFormSheet.kt
│   │   ├── BuySellDetailScreen.kt
│   │   ├── SoldFormSheet.kt
│   │   └── ProfitAllocationSheet.kt
│   ├── receivables/
│   │   ├── ReceivablesScreen.kt
│   │   ├── ReceivableViewModel.kt
│   │   ├── ReceivableFormSheet.kt
│   │   ├── PersonReceivablesScreen.kt
│   │   └── PaymentHistoryScreen.kt
│   ├── assets/
│   │   ├── AssetsScreen.kt
│   │   ├── AssetViewModel.kt
│   │   └── AssetFormSheet.kt
│   ├── analytics/
│   │   ├── AnalyticsScreen.kt
│   │   ├── AnalyticsViewModel.kt
│   │   ├── OverallAnalyticsView.kt
│   │   ├── BuySellAnalyticsView.kt
│   │   ├── InvestmentAnalyticsView.kt
│   │   └── ExpenseAnalyticsView.kt
│   ├── activitylog/
│   │   ├── ActivityLogScreen.kt
│   │   └── ActivityLogViewModel.kt
│   ├── settings/
│   │   ├── SettingsScreen.kt
│   │   └── SettingsViewModel.kt
│   ├── components/
│   │   ├── GlassCard.kt           # Elevated card with Material 3 styling
│   │   ├── CurrencyText.kt        # PHP formatting composable
│   │   ├── CategoryBadge.kt       # Colored category chips
│   │   ├── StatusBadge.kt         # Status indicator chips
│   │   ├── EmptyStateView.kt      # Empty list placeholder
│   │   ├── ExpenseSummaryCard.kt
│   │   ├── NetworkStatusBanner.kt
│   │   ├── ConfirmationDialog.kt  # Material 3 AlertDialog
│   │   └── ToastSnackbar.kt       # Snackbar with undo action
│   └── theme/
│       ├── Theme.kt               # Material 3 theme with dynamic color
│       ├── Color.kt               # Module-specific colors
│       └── Type.kt                # Typography scale
├── util/
│   ├── CurrencyFormatter.kt       # PHP formatting
│   ├── DateExtensions.kt          # Date formatting utilities
│   ├── Constants.kt               # CURRENT_YEAR = 2026, SAVINGS_LABELS, KNOWN_BANKS
│   └── NetworkMonitor.kt          # Connectivity observer
└── navigation/
    ├── NavGraph.kt                 # Navigation graph definition
    ├── NavigationManager.kt        # Tab + segment state
    └── DeepLinkHandler.kt          # budgy:// URI handling
```

## Data Models

All 17 models ported as Kotlin data classes with identical Firestore field names to ensure cross-platform compatibility.

### Enums (matching iOS values exactly for Firestore compatibility)

| Enum | Values |
|------|--------|
| WalletType | bank, cash |
| ExpenseCategory | food, transport, utilities, shopping, entertainment, health, other |
| InvestmentType | stock, crypto, other |
| InvestmentSource | salary, buySellProfits, oldSavings |
| AssetCategory | cellphone, laptop, tablet, accessory, other |
| ItemType | phone, laptop, tablet, accessory, other |
| BuySellStatus | available, pending, sold |
| DepositSource | salary, milestone, buySellProfit, oldSavings, other |
| WalletTransactionType | deposit, expense, withdrawal, investment, tpsl, buySellBuy, buySellSold, receivableOut, receivablePayment, asset |
| ActivityLogType | expense, investment, deposit, asset, buySell, receivable, wallet, transfer, savings, payment |
| ActivityLogAction | add, edit, delete |

### Firestore Serialization

Use `@PropertyName` annotations from Firebase SDK to map Kotlin property names to Firestore field names where they differ. All enum values stored as lowercase strings to match iOS.

## Firestore Structure (Shared with iOS)

```
users/{uid}/
├── expenses/{docId}
├── wallets/{docId}
├── deposits/{docId}
├── withdrawals/{docId}
├── investments/{docId}
├── investmentExits/{docId}
├── buySellTransactions/{docId}
├── assets/{docId}
├── receivables/{docId}
│   └── payments/{docId}
├── profitAllocations/{docId}
├── savingsBreakdown/{docId}
├── watchlist/{docId}
└── activityLog/{docId}
```

All reads use real-time snapshot listeners (Firestore `addSnapshotListener`), converted to Kotlin `Flow` via `callbackFlow`. Writes use batch operations for multi-document consistency.

## Features — Android Implementation Details

### 1. Authentication (AuthRepository + AuthViewModel)

- Google Sign-In via Firebase Auth (Android Credential Manager API)
- Account switching: sign out current account silently, present account picker
- Auth state exposed as `StateFlow<AuthState>` (Loading, Authenticated, Unauthenticated)
- User data: uid, displayName, email, photoUrl

### 2. Dashboard (DashboardScreen + DashboardViewModel)

- Grand total = wallets + investments + receivables + assets + B&S inventory
- 4 stat cards: Wallets total, This Week expenses, Investment value, B&S profit
- Expense by Category: Vico pie chart
- Monthly expenses: Vico bar chart
- Quick expense FAB opens bottom sheet
- Eye icon toggle to mask/reveal amounts (shared via SettingsViewModel)

### 3. Finance — Wallets (WalletsSection + WalletViewModel)

- Bank and Cash sections with headers
- Long-press context menu: Deposit, Transfer, Edit, Delete
- Tap navigates to WalletTransactionHistoryScreen
- Total balance footer
- Transfer: deduct from source + fee, add to destination (batch write)
- Fee auto-recorded as expense

### 4. Finance — Expenses (ExpensesSection + ExpenseViewModel)

- Horizontal scrollable category filter chips
- Period filter: All, Today, This Week, This Month
- Sort: Date (Newest/Oldest), Amount (High/Low)
- Grouped by date with section headers
- Long-press: Edit, Delete
- Receipt scanner via ML Kit text recognition
- Export to CSV/PDF via Android share intent
- Swipe-to-delete with undo snackbar

### 5. Investments (InvestmentsScreen + InvestmentViewModel)

- Tab row filter: All, Crypto, Stock, Other
- Portfolio summary cards (VOO-specific tracking)
- Investment list with long-press context menu
- TP/SL bottom sheet: enter exit price, select destination wallets, calculate profit/loss
- Exited investments at 50% alpha
- Sort: Date, Amount
- Star icon navigates to WatchlistScreen
- Real-time VOO price via StockPriceViewModel (API call)
- USD/PHP exchange rate via ExchangeRateViewModel

### 6. Buy & Sell (BuySellScreen + BuySellViewModel)

- Profit summary card at top
- Status counts: Sold, Pending, Available
- Filter chips: Status, Item Type
- Sort: Date, Profit
- Long-press: Mark Sold (for available items), Edit, Delete
- Sold form: buyer name, sell price, date, multi-destination routing
- Profit allocation tracking sheet
- Multi-source funding on buy (split across wallets)

### 7. Receivables (ReceivablesScreen + ReceivableViewModel)

- Two tabs: Ongoing, Completed
- Grouped by person name
- Tap person -> PersonReceivablesScreen (list of receivables)
- Tap receivable -> PaymentHistoryScreen
- Record payment: amount, date, multi-destination wallet routing
- Filter: Reimbursement vs loan
- Sort: Amount, Name

### 8. Assets (AssetsScreen + AssetViewModel)

- Categorized sections: Cellphone, Laptop, Tablet, Accessory, Other
- Long-press: Edit, Delete
- Form: name, category, amount, source wallet (optional)
- Source wallet debited on add, restored on delete

### 9. Analytics (AnalyticsScreen + AnalyticsViewModel)

- Date range selector: All, Today, This Week, This Month, This Year, Custom
- 4 tab views:
  - Overall: net worth breakdown, income vs expenses
  - Buy & Sell: profit by type, conversion rates
  - Investments: portfolio performance
  - Expenses: category breakdown, trends
- All charts via Vico library

### 10. Activity Log (ActivityLogScreen + ActivityLogViewModel)

- Reverse chronological list
- Filter chips: by type (10 categories), by action (Add, Edit, Delete)
- Immutable records — no edit/delete actions
- Timestamp display

### 11. Settings (SettingsScreen + SettingsViewModel)

- Theme toggle: Light / Dark / System (persisted in DataStore)
- Expense reminder scheduling via WorkManager
- Multiple reminders per day
- About section

### 12. More Menu

- Profile card: name, email, photo, account switch button
- Navigation to: Assets, Buy & Sell, Receivables, Analytics, Activity Log, Settings
- Sign Out button

## Navigation Structure

```
MainActivity (single activity)
└── NavHost
    ├── LoginScreen
    ├── MainScaffold (with BottomNavigationBar)
    │   ├── Tab 0: DashboardScreen
    │   ├── Tab 1: FinanceScreen (Wallets | Expenses segment)
    │   ├── Tab 2: InvestmentsScreen
    │   └── Tab 3: MoreMenuScreen
    │       ├── AssetsScreen
    │       ├── BuySellScreen
    │       │   └── BuySellDetailScreen
    │       ├── ReceivablesScreen
    │       │   ├── PersonReceivablesScreen
    │       │   └── PaymentHistoryScreen
    │       ├── AnalyticsScreen
    │       ├── ActivityLogScreen
    │       └── SettingsScreen
    ├── WalletTransactionHistoryScreen
    └── WatchlistScreen
```

### Deep Links

Intent filter for `budgy://` scheme:
- `budgy://add-expense` -> Open quick expense sheet
- `budgy://dashboard` -> Navigate to dashboard tab

## Android-Specific Adaptations

| iOS Pattern | Android Equivalent |
|-------------|-------------------|
| SwiftUI sheets | Material 3 ModalBottomSheet |
| Swipe actions on list rows | Long-press context menu (DropdownMenu) |
| @Observable ViewModel | Hilt ViewModel + StateFlow |
| Combine/async-await | Coroutines + Flow |
| Charts framework | Vico library |
| UserNotifications | WorkManager + NotificationManager |
| App Intents (Siri) | Not ported initially |
| UIKit haptics | Android HapticFeedbackConstants |
| Toast with undo | Material 3 Snackbar with action |
| NavigationStack | NavHost + NavController |
| GlassCard (blur) | ElevatedCard with Material 3 tonalElevation |
| Gradient login background | Brush.linearGradient in Compose |

## Dependencies

```kotlin
// build.gradle.kts (app)
dependencies {
    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")

    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth:21.0.0")
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")

    // Jetpack Compose
    implementation(platform("androidx.compose:compose-bom:2024.12.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.9.0")
    implementation("androidx.navigation:navigation-compose:2.8.0")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.51")
    kapt("com.google.dagger:hilt-compiler:2.51")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // Lifecycle + ViewModel
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.0")

    // Charts
    implementation("com.patrykandpatrick.vico:compose-m3:2.0.0-alpha.28")

    // ML Kit (OCR)
    implementation("com.google.mlkit:text-recognition:16.0.0")

    // WorkManager (notifications)
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    // DataStore (preferences)
    implementation("androidx.datastore:datastore-preferences:1.1.0")

    // Coil (image loading for profile photos)
    implementation("io.coil-kt:coil-compose:2.6.0")
}
```

## Testing Strategy

- **Unit tests**: Repository logic, ViewModel state transitions, currency formatting
- **Integration tests**: Firestore operations against Firebase emulator
- **UI tests**: Compose testing with `createComposeRule()` for critical flows
- **Key test scenarios**: Multi-source transactions, TP/SL routing, transfer with fees, partial payments

## Out of Scope

- Siri Shortcuts equivalent (Google Assistant actions) — can be added later
- Widgets — can be added later
- Wear OS companion — not planned
- Offline-first with Room cache — Firestore handles offline persistence natively
