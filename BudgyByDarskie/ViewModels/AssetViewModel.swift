import Foundation
import FirebaseFirestore

@Observable
class AssetViewModel {
    var assets: [Asset] = []
    var isLoading = true
    var errorMessage: String?

    private var listener: ListenerRegistration?

    var totalAssets: Double { assets.reduce(0) { $0 + $1.amount } }

    var byCategory: [AssetCategory: [Asset]] {
        Dictionary(grouping: assets, by: \.category)
    }

    func subscribe(uid: String, year: Int = CURRENT_YEAR) {
        listener?.remove()
        isLoading = true
        listener = AssetService.subscribe(uid: uid, year: year) { [weak self] assets in
            self?.assets = assets
            self?.isLoading = false
        }
    }

    func unsubscribe() {
        listener?.remove()
        listener = nil
    }

    func add(uid: String, asset: Asset) async -> String? {
        do {
            return try await AssetService.add(uid: uid, asset: asset)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func update(uid: String, assetId: String, oldAmount: Double, oldSourceId: String, asset: Asset) async {
        do {
            try await AssetService.update(uid: uid, assetId: assetId, oldAmount: oldAmount, oldSourceId: oldSourceId, asset: asset)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(uid: String, assetId: String, sourceId: String, amount: Double) async {
        do {
            try await AssetService.delete(uid: uid, assetId: assetId, sourceId: sourceId, amount: amount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
