import SwiftUI

struct ProfitAllocationSheet: View {
    @Bindable var profitVM: ProfitAllocationViewModel
    let totalProfit: Double
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var destType = "investment"
    @State private var amount = ""

    var unallocated: Double { totalProfit - profitVM.totalAllocated }

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    HStack {
                        Text("Total Profit")
                        Spacer()
                        Text(formatPhp(totalProfit)).monospacedDigit().fontWeight(.bold)
                    }
                    HStack {
                        Text("Allocated")
                        Spacer()
                        Text(formatPhp(profitVM.totalAllocated)).monospacedDigit()
                    }
                    HStack {
                        Text("Unallocated")
                        Spacer()
                        Text(formatPhp(unallocated))
                            .monospacedDigit()
                            .foregroundStyle(unallocated > 0 ? .orange : .green)
                    }
                }

                Section("Allocations") {
                    ForEach(profitVM.allocations) { alloc in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(alloc.label).fontWeight(.medium)
                                Text(alloc.destType == "investment" ? "Investment" : "Wallet")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(formatPhp(alloc.amount)).monospacedDigit()
                        }
                    }
                }

                Section("Add Allocation") {
                    TextField("Label", text: $label)
                    Picker("Destination", selection: $destType) {
                        Text("Investment").tag("investment")
                        Text("Wallet").tag("wallet")
                    }
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Button("Add") {
                        guard !label.isEmpty, let amt = Double(amount) else { return }
                        let alloc = ProfitAllocation(
                            label: label,
                            destType: destType,
                            amount: amt,
                            year: CURRENT_YEAR
                        )
                        Task {
                            guard let uid = AuthService.shared.uid else { return }
                            await profitVM.add(uid: uid, allocation: alloc)
                            label = ""
                            amount = ""
                        }
                    }
                    .disabled(label.isEmpty || amount.isEmpty)
                }
            }
            .navigationTitle("Profit Allocations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
