import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    private var productIDs = ["com.yourapp.premium.monthly", "com.yourapp.premium.yearly"]
    private var products: [Product] = []
    private var purchasedProductIDs: Set<String> = []
    
    private init() {
        Task {
            do {
                _ = try await loadProducts()
                await updatePurchasedProducts()
            } catch {
                print("初期化時の商品読み込みに失敗: \(error.localizedDescription)")
            }
        }
    }
    
    func loadProducts() async throws -> [Product] {
        do {
            products = try await Product.products(for: productIDs)
            return products
        } catch {
            throw error
        }
    }
    
    func purchase(_ product: Product) async throws {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchasedProducts()
                case .unverified:
                    throw SubscriptionError.verificationFailed
                }
            case .userCancelled:
                throw SubscriptionError.userCancelled
            case .pending:
                throw SubscriptionError.pending
            @unknown default:
                throw SubscriptionError.unknown
            }
        } catch {
            throw error
        }
    }
    
    func restorePurchases() async throws {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            throw error
        }
    }
    
    func isPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    private func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                purchasedProductIDs.insert(transaction.productID)
            case .unverified:
                continue
            }
        }
    }
}

enum SubscriptionError: LocalizedError {
    case verificationFailed
    case userCancelled
    case pending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "購入の検証に失敗しました"
        case .userCancelled:
            return "購入がキャンセルされました"
        case .pending:
            return "購入が保留中です"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
} 