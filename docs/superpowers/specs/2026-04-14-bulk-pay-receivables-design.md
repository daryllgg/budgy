# Bulk Pay Receivables Design

## Overview

Add long-press multi-select on ongoing receivables within `PersonReceivablesView`, with a bulk "Mark as Paid" action that opens a modal for allocating the combined total across multiple destination wallets.

## User Flow

1. User is in `PersonReceivablesView`, viewing the **Ongoing** tab
2. **Long press** on any receivable row enters selection mode — that row gets checked
3. In selection mode, **tapping** any ongoing receivable row toggles its selection (checkmark on/off)
4. A **floating "Mark as Paid" button** appears at the bottom showing selected count and combined total (e.g. "Mark 3 as Paid - PHP 5,000.00")
5. Tapping the button opens **`BulkPaymentSheet`**
6. The sheet displays:
   - List of selected receivables with their remaining amounts (read-only summary)
   - Total amount (sum of all remaining balances)
   - **Destination Wallets** section — same UX as existing `PaymentFormSheet`: picker to select wallet, enter amount, add more wallets. The sum of wallet amounts must equal the total.
   - Date picker (defaults to today)
   - Notes field
7. User allocates the total across one or more wallets and taps **Save**
8. On save: all receivables are marked fully paid, wallet balances credited, payment records created
9. Selection mode exits, toast confirmation shown

### Exiting Selection Mode

- Tap "Cancel" text button in the toolbar (appears during selection mode)
- Or deselect all items manually

## Architecture

### Modified Files

**`PersonReceivablesView.swift`**
- Add `@State private var selectedIds: Set<String>` for tracking selected receivable IDs
- Add `@State private var isSelecting: Bool` to track selection mode
- Add `@State private var showBulkPayment: Bool` for the sheet
- Long press gesture on each `ReceivableRow` in the ongoing section to toggle selection
- In selection mode: replace `NavigationLink` behavior with tap-to-toggle-select
- Show checkmark overlay on selected rows
- Show floating bottom button when `!selectedIds.isEmpty`
- Show "Cancel" toolbar button during selection mode to exit

**`ReceivableRow.swift`**
- No changes needed — selection chrome is handled by the parent view wrapping the row

### New Files

**`BulkPaymentSheet.swift`** (in `Views/Receivables/`)
- Receives: selected `[Receivable]` items, available `[Wallet]` list, `onSave` callback
- Displays read-only summary of selected receivables and their remaining amounts
- Shows total amount (fixed, not editable)
- Destination wallets section — reuses the same pattern as `PaymentFormSheet`:
  - List of added destinations with wallet name, amount, remove button
  - Picker + amount field + add button for new destinations
  - Validates that destination amounts sum to the total
- Date picker, notes field
- Save button disabled until destinations sum equals total

### Service Layer

**`ReceivablePaymentService.swift`**
- Add new static method: `bulkPay(uid:receivables:destinations:date:notes:)`
- Uses a single Firestore `WriteBatch` for atomicity
- For each selected receivable:
  - Creates a `ReceivablePayment` record in that receivable's `payments` subcollection
  - The payment amount = that receivable's `remaining`
  - The payment's `destinations` are proportionally allocated based on the user's wallet split (each receivable's share of the total determines its share of each wallet destination)
  - Updates the receivable's `totalPaid` by incrementing with the remaining amount
- For each destination wallet:
  - Increments the wallet's `balance` by the wallet's total allocated amount (sum across all receivables for that wallet)
- Logs a single activity log entry for the bulk payment

### Proportional Destination Split

When the user allocates the total (e.g. PHP 5,000) across wallets (e.g. GCash: 3,000, BDO: 2,000), each individual receivable's payment record gets destinations proportional to the overall split:

- Ratios: GCash = 3000/5000 = 60%, BDO = 2000/5000 = 40%
- Receivable A (remaining 2,000): GCash 1,200 + BDO 800
- Receivable B (remaining 3,000): GCash 1,800 + BDO 1,200

This keeps individual payment history accurate and consistent with the existing single-payment flow.

Rounding: use the largest-remainder method to ensure per-receivable destination amounts sum exactly to the receivable's remaining. Process the last receivable as the remainder to avoid floating-point drift.

## Edge Cases

- **Single selection**: Works fine — equivalent to paying one receivable in full with wallet selection
- **Already fully paid receivable**: Only ongoing (not fully paid) receivables are shown in the ongoing tab, so this can't happen
- **Wallet amount mismatch**: Save button stays disabled until destination amounts exactly equal the total
- **Empty wallets list**: Same behavior as existing PaymentFormSheet — user must have at least one wallet
- **Mid-selection data change**: Firestore listener may update receivables while selecting. If a selected receivable becomes fully paid externally, remove it from selection. If it no longer exists, remove from selection.

## UI Details

- Selected rows show a **checkmark circle** on the leading edge
- Unselected rows (in selection mode) show an **empty circle** on the leading edge
- Floating button uses the app's accent color, positioned above the tab bar / bottom safe area
- The bulk payment sheet uses `.presentationDetents([.medium, .large])` consistent with existing sheets
- Haptic feedback on successful bulk payment (`hapticSuccess()`)
- Toast message: "Marked X receivables as paid"
