import Foundation
import FirebaseFirestore

@Observable
class ProfitAllocationViewModel {
    var allocations: [ProfitAllocation] = []
    var isLoading = true
    var errorMessage: String?

    private var listener: ListenerRegistration?

    var totalAllocated: Double { allocations.reduce(0) { $0 + $1.amount } }

    var toInvestments: Double {
        allocations.filter { $0.destType == "investment" }.reduce(0) { $0 + $1.amount }
    }

    var toWallets: Double {
        allocations.filter { $0.destType == "wallet" }.reduce(0) { $0 + $1.amount }
    }

    func subscribe(uid: String, year: Int = CURRENT_YEAR) {
        listener?.remove()
        isLoading = true
        listener = ProfitAllocationService.subscribe(uid: uid, year: year) { [weak self] items in
            self?.allocations = items
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
        listener = nil
    }

    func add(uid: String, allocation: ProfitAllocation) async {
        do {
            try await ProfitAllocationService.add(uid: uid, allocation: allocation)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(uid: String, allocationId: String, data: [String: Any]) async {
        do {
            try await ProfitAllocationService.update(uid: uid, allocationId: allocationId, data: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(uid: String, allocationId: String) async {
        do {
            try await ProfitAllocationService.delete(uid: uid, allocationId: allocationId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
