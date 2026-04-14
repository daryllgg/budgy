# Bulk Pay Receivables Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add long-press multi-select on ongoing receivables with a bulk "Mark as Paid" flow that supports allocating the total across multiple destination wallets.

**Architecture:** Add selection state to `PersonReceivablesView`, a new `BulkPaymentSheet` for wallet allocation, and a `bulkPay` batch method on `ReceivablePaymentService`. The bulk payment creates individual `ReceivablePayment` records per receivable with proportionally split wallet destinations, all in a single Firestore batch.

**Tech Stack:** SwiftUI, Firebase Firestore (batch writes)

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `BudgyByDarskie/Services/ReceivablePaymentService.swift` | Modify | Add `bulkPay` static method |
| `BudgyByDarskie/Views/Receivables/BulkPaymentSheet.swift` | Create | Modal for wallet allocation on bulk pay |
| `BudgyByDarskie/Views/Receivables/PersonReceivablesView.swift` | Modify | Add selection mode, long-press, floating button |
| `BudgyByDarskie.xcodeproj/project.pbxproj` | Modify | Register new file |

---

### Task 1: Add `bulkPay` to ReceivablePaymentService

**Files:**
- Modify: `BudgyByDarskie/Services/ReceivablePaymentService.swift`

- [ ] **Step 1: Add the `bulkPay` static method**

Add this method after the existing `delete` method in `ReceivablePaymentService`:

```swift
static func bulkPay(uid: String, receivables: [Receivable], destinations: [PaymentDestination], date: Date, notes: String) async throws {
    let batch = db.batch()
    let totalAmount = receivables.reduce(0.0) { $0 + $1.remaining }

    // Aggregate wallet totals for balance updates
    var walletTotals: [String: Double] = [:]

    for (index, rec) in receivables.enumerated() {
        guard let recId = rec.id else { continue }
        let recRemaining = rec.remaining

        // Proportionally split destinations for this receivable
        let recDestinations: [PaymentDestination]
        if index == receivables.count - 1 {
            // Last receivable gets remainder to avoid floating-point drift
            var usedPerWallet: [String: Double] = [:]
            for dest in destinations {
                usedPerWallet[dest.walletId] = walletTotals[dest.walletId] ?? 0
            }
            recDestinations = destinations.map { dest in
                let totalForWallet = dest.amount
                let usedSoFar = usedPerWallet[dest.walletId] ?? 0
                let thisAmount = totalForWallet - usedSoFar
                return PaymentDestination(walletId: dest.walletId, walletName: dest.walletName, amount: thisAmount)
            }.filter { $0.amount > 0 }
        } else {
            let ratio = totalAmount > 0 ? recRemaining / totalAmount : 0
            recDestinations = destinations.map { dest in
                let thisAmount = (dest.amount * ratio * 100).rounded() / 100
                return PaymentDestination(walletId: dest.walletId, walletName: dest.walletName, amount: thisAmount)
            }.filter { $0.amount > 0 }
        }

        // Track wallet totals for remainder calculation
        for dest in recDestinations {
            walletTotals[dest.walletId, default: 0] += dest.amount
        }

        // Create payment record
        let destData = recDestinations.map { [
            "walletId": $0.walletId,
            "walletName": $0.walletName,
            "amount": $0.amount
        ] as [String: Any] }

        let paymentRef = db.collection("users").document(uid).collection("receivables")
            .document(recId).collection("payments").document()
        batch.setData([
            "amount": recRemaining,
            "date": Timestamp(date: date),
            "destinations": destData,
            "notes": notes,
            "createdAt": FieldValue.serverTimestamp(),
        ], forDocument: paymentRef)

        // Update receivable totalPaid
        let receivableRef = db.collection("users").document(uid).collection("receivables").document(recId)
        batch.updateData([
            "totalPaid": FieldValue.increment(recRemaining),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: receivableRef)
    }

    // Update wallet balances
    for dest in destinations {
        let walletRef = db.collection("users").document(uid).collection("wallets").document(dest.walletId)
        batch.updateData([
            "balance": FieldValue.increment(dest.amount),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: walletRef)
    }

    batch.commit(completion: nil)
    ActivityLogService.log(uid: uid, type: .payment, action: .add, description: "Bulk payment (\(receivables.count) receivables)", amount: totalAmount)
}
```

- [ ] **Step 2: Verify it compiles**

Run:
```bash
xcodebuild -project BudgyByDarskie.xcodeproj -scheme BudgyByDarskie -destination 'platform=iOS,id=00008140-000A152A01F3001C' -allowProvisioningUpdates build 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add BudgyByDarskie/Services/ReceivablePaymentService.swift
git commit -m "feat: add bulkPay method to ReceivablePaymentService"
```

---

### Task 2: Create BulkPaymentSheet

**Files:**
- Create: `BudgyByDarskie/Views/Receivables/BulkPaymentSheet.swift`

- [ ] **Step 1: Create the BulkPaymentSheet view**

Create `BudgyByDarskie/Views/Receivables/BulkPaymentSheet.swift` with:

```swift
import SwiftUI

struct BulkPaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let receivables: [Receivable]
    let wallets: [Wallet]
    let onSave: ([PaymentDestination], Date, String) async throws -> Void

    @State private var date = Date()
    @State private var notes = ""
    @State private var destinations: [PaymentDestination] = []
    @State private var newWalletId = ""
    @State private var newWalletAmount = ""
    @State private var isSaving = false

    private var totalAmount: Double {
        receivables.reduce(0) { $0 + $1.remaining }
    }

    private var destinationsTotal: Double {
        var total = destinations.reduce(0) { $0 + $1.amount }
        if let pending = pendingDestinationAmount {
            total += pending
        }
        return total
    }

    private var pendingDestinationAmount: Double? {
        guard !newWalletId.isEmpty, let amt = Double(newWalletAmount), amt > 0 else { return nil }
        return amt
    }

    private var remainingToAllocate: Double {
        totalAmount - destinationsTotal
    }

    private var canSave: Bool {
        !isSaving && !destinations.isEmpty || pendingDestinationAmount != nil
    }

    private var allDestinations: [PaymentDestination] {
        var result = destinations
        if !newWalletId.isEmpty, let amt = Double(newWalletAmount), amt > 0 {
            let name = wallets.first(where: { $0.id == newWalletId })?.name ?? ""
            result.append(PaymentDestination(walletId: newWalletId, walletName: name, amount: amt))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Selected Receivables") {
                    ForEach(receivables) { rec in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.receivableDescription.isEmpty ? rec.name : rec.receivableDescription)
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text(formatPhp(rec.remaining))
                                .monospacedDigit()
                                .foregroundStyle(.orange)
                        }
                    }
                    HStack {
                        Text("Total").fontWeight(.semibold)
                        Spacer()
                        Text(formatPhp(totalAmount))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Destination Wallets") {
                    ForEach(destinations) { dest in
                        HStack {
                            Text(dest.walletName)
                            Spacer()
                            Text(formatPhp(dest.amount)).monospacedDigit()
                            Button { destinations.removeAll(where: { $0.walletId == dest.walletId }) } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                            }
                        }
                    }
                    HStack {
                        Picker("Wallet", selection: $newWalletId) {
                            Text("Select").tag("")
                            ForEach(wallets) { w in
                                Text("\(w.name) (\(formatPhp(w.balance)))").tag(w.id ?? "")
                            }
                        }
                        .labelsHidden()
                        TextField("Amount", text: $newWalletAmount)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                        Button {
                            guard let amt = Double(newWalletAmount), !newWalletId.isEmpty else { return }
                            let name = wallets.first(where: { $0.id == newWalletId })?.name ?? ""
                            destinations.append(PaymentDestination(walletId: newWalletId, walletName: name, amount: amt))
                            newWalletId = ""
                            newWalletAmount = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                    if remainingToAllocate > 0.01 {
                        HStack {
                            Text("Remaining to allocate")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatPhp(remainingToAllocate))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.orange)
                        }
                    }
                }

                TextField("Notes", text: $notes)
            }
            .navigationTitle("Bulk Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pay") {
                        isSaving = true
                        Task {
                            try? await onSave(allDestinations, date, notes)
                            dismiss()
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
        }
        .onChange(of: newWalletId) { _, newId in
            if !newId.isEmpty && newWalletAmount.isEmpty && destinations.isEmpty {
                newWalletAmount = String(format: "%.0f", totalAmount)
            }
        }
        .presentationDetents([.medium, .large])
    }
}
```

- [ ] **Step 2: Add the file to the Xcode project**

The file must be added to `project.pbxproj`. Run:
```bash
# The file will be auto-discovered by Xcode if using folder references,
# or needs manual pbxproj entry. Build to verify.
xcodebuild -project BudgyByDarskie.xcodeproj -scheme BudgyByDarskie -destination 'platform=iOS,id=00008140-000A152A01F3001C' -allowProvisioningUpdates build 2>&1 | tail -5
```

If the file is not picked up, add it to `project.pbxproj` by following the same pattern used for other files in the `Views/Receivables` group (search for `PaymentHistoryView.swift` entries in `project.pbxproj` and replicate the pattern for `BulkPaymentSheet.swift`).

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add BudgyByDarskie/Views/Receivables/BulkPaymentSheet.swift BudgyByDarskie.xcodeproj/project.pbxproj
git commit -m "feat: add BulkPaymentSheet view for multi-wallet allocation"
```

---

### Task 3: Add selection mode to PersonReceivablesView

**Files:**
- Modify: `BudgyByDarskie/Views/Receivables/PersonReceivablesView.swift`

- [ ] **Step 1: Add selection state properties**

Add these `@State` properties after the existing `@State` declarations (after line 15 `@State private var newPersonName = ""`):

```swift
@State private var selectedIds: Set<String> = []
@State private var isSelecting = false
@State private var showBulkPayment = false
```

- [ ] **Step 2: Add computed property for selected receivables**

Add this computed property after the existing `lastUpdated` computed property (after line 46):

```swift
private var selectedReceivables: [Receivable] {
    ongoingReceivables.filter { selectedIds.contains($0.id ?? "") }
}

private var selectedTotal: Double {
    selectedReceivables.reduce(0) { $0 + $1.remaining }
}
```

- [ ] **Step 3: Replace the ongoing receivables ForEach with selection-aware rows**

Replace the `ForEach(displayedReceivables)` block (lines 95-111) with:

```swift
ForEach(displayedReceivables) { rec in
    if isSelecting && selectedTab == 0 {
        Button {
            toggleSelection(rec)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedIds.contains(rec.id ?? "") ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedIds.contains(rec.id ?? "") ? .green : .secondary)
                    .font(.title3)
                ReceivableRow(receivable: rec, showName: false)
            }
        }
        .tint(.primary)
    } else {
        NavigationLink {
            PaymentHistoryView(receivable: rec, wallets: walletVM.wallets)
        } label: {
            ReceivableRow(receivable: rec, showName: false)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { deleteTarget = rec } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            Button { editingReceivable = rec } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .onLongPressGesture {
            if selectedTab == 0 {
                isSelecting = true
                toggleSelection(rec)
            }
        }
    }
}
```

- [ ] **Step 4: Add the toggleSelection helper method**

Add this method at the end of the struct, before the closing brace of `PersonReceivablesView`:

```swift
private func toggleSelection(_ rec: Receivable) {
    guard let id = rec.id else { return }
    if selectedIds.contains(id) {
        selectedIds.remove(id)
        if selectedIds.isEmpty {
            isSelecting = false
        }
    } else {
        selectedIds.insert(id)
    }
}
```

- [ ] **Step 5: Add floating "Mark as Paid" button**

Wrap the existing `VStack(spacing: 0)` body content in a `ZStack(alignment: .bottom)` and add the floating button. Replace the body's `VStack(spacing: 0) {` opening (line 50) through the closing of that VStack with:

```swift
ZStack(alignment: .bottom) {
    VStack(spacing: 0) {
        Picker("Status", selection: $selectedTab) {
            Text("Ongoing (\(ongoingReceivables.count))").tag(0)
            Text("Completed (\(completedReceivables.count))").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 12)

        List {
            Section {
                HStack {
                    Text("Total")
                    Spacer()
                    Text(formatPhp(totalAmount)).monospacedDigit()
                }
                HStack {
                    Text("Paid")
                    Spacer()
                    Text(formatPhp(totalPaid)).monospacedDigit().foregroundStyle(.green)
                }
                HStack {
                    Text("Remaining")
                    Spacer()
                    Text(formatPhp(remaining))
                        .monospacedDigit()
                        .foregroundStyle(remaining > 0 ? .orange : .green)
                }
                if let lastUpdated {
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(lastUpdated.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if displayedReceivables.isEmpty {
                Section {
                    Text(selectedTab == 0 ? "No ongoing receivables" : "No completed receivables")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(displayedReceivables) { rec in
                        // (selection-aware rows from Step 3)
                    }
                }
            }
        }
    }

    if isSelecting && !selectedIds.isEmpty {
        Button {
            showBulkPayment = true
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Mark \(selectedIds.count) as Paid - \(formatPhp(selectedTotal))")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}
```

- [ ] **Step 6: Add Cancel button to toolbar during selection mode**

Modify the existing toolbar section. Replace the toolbar modifier (lines 117-131) with:

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        HStack(spacing: 12) {
            if isSelecting {
                Button("Cancel") {
                    selectedIds.removeAll()
                    isSelecting = false
                }
            } else {
                Button {
                    newPersonName = personName
                    showRenameAlert = true
                } label: {
                    Image(systemName: "pencil")
                }
                Button { showAddReceivable = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}
```

- [ ] **Step 7: Add the BulkPaymentSheet presentation**

Add this `.sheet` modifier after the existing `.sheet(item: $editingReceivable)` block (after line 175):

```swift
.sheet(isPresented: $showBulkPayment) {
    BulkPaymentSheet(receivables: selectedReceivables, wallets: walletVM.wallets) { destinations, date, notes in
        guard let uid = authVM.uid else { return }
        try await ReceivablePaymentService.bulkPay(
            uid: uid,
            receivables: selectedReceivables,
            destinations: destinations,
            date: date,
            notes: notes
        )
        hapticSuccess()
        toast.show("Marked \(selectedIds.count) receivables as paid")
        selectedIds.removeAll()
        isSelecting = false
    }
}
```

- [ ] **Step 8: Clear selection when switching tabs**

Add this modifier after the `.onDisappear` block:

```swift
.onChange(of: selectedTab) { _, _ in
    selectedIds.removeAll()
    isSelecting = false
}
```

- [ ] **Step 9: Build and verify**

Run:
```bash
xcodebuild -project BudgyByDarskie.xcodeproj -scheme BudgyByDarskie -destination 'platform=iOS,id=00008140-000A152A01F3001C' -allowProvisioningUpdates build 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`

- [ ] **Step 10: Commit**

```bash
git add BudgyByDarskie/Views/Receivables/PersonReceivablesView.swift
git commit -m "feat: add long-press multi-select and bulk pay to PersonReceivablesView"
```

---

### Task 4: Deploy and test on device

**Files:** None (testing only)

- [ ] **Step 1: Build for device**

```bash
xcodebuild -project BudgyByDarskie.xcodeproj -scheme BudgyByDarskie -destination 'platform=iOS,id=00008140-000A152A01F3001C' -allowProvisioningUpdates build
```

- [ ] **Step 2: Install on iPhone**

```bash
xcrun devicectl device install app --device 9158319D-E16A-5C88-9122-7917A7507B77 ~/Library/Developer/Xcode/DerivedData/BudgyByDarskie-bbvewswkvnoglgaoymntcojlcypp/Build/Products/Debug-iphoneos/BudgyByDarskie.app
```

- [ ] **Step 3: Launch**

```bash
xcrun devicectl device process launch --device 9158319D-E16A-5C88-9122-7917A7507B77 com.darskie.budgybydarskie
```

- [ ] **Step 4: Manual test checklist**

Test in the app:
1. Navigate to Receivables → tap a person with multiple ongoing receivables
2. Long press a receivable — verify checkmark appears and selection mode activates
3. Tap more receivables — verify they toggle selection
4. Verify floating button shows correct count and total
5. Tap "Mark as Paid" — verify BulkPaymentSheet opens with correct receivables and total
6. Add wallet destinations, verify remaining-to-allocate updates
7. Tap Pay — verify receivables move to Completed tab
8. Check wallet balances updated correctly
9. Check individual payment history for each receivable shows the payment record
10. Tap Cancel in toolbar — verify selection clears
11. Switch tabs — verify selection clears
