import Foundation
import StoreKit

/// アプリ内課金を管理するクラス（StoreKit 2をラップしてレガシーコードとの互換性を提供）
@MainActor  // MainActor注釈を追加
class InAppPurchaseManager: NSObject, ObservableObject {
    static let shared = InAppPurchaseManager()
    
    // StoreKit 2 マネージャー
    private let subscriptionManager = SubscriptionManager.shared
    
    // デバッグモード用設定（StoreKit 2マネージャーから移譲）
    var debugPremiumEnabled: Bool {
        get { return subscriptionManager.debugPremiumEnabled }
        set { subscriptionManager.debugPremiumEnabled = newValue }
    }
    
    // 購入履歴をクリア
    func clearPurchases() {
        purchasedProducts.removeAll()
        // SubscriptionManagerにも委託
        subscriptionManager.clearPurchasedProducts()
        objectWillChange.send()
    }
    
    // プレミアム機能の表示/非表示を管理するフラグ
    static let showPremiumFeatures = SubscriptionManager.showPremiumFeatures
    
    // 利用可能な商品のID（StoreKit 2で使用している新しいIDにマッピング）
    let monthlySubscriptionID = "com.yourdomain.animalgestione.premium_monthly"
    let removeAdsProductID = "com.yourdomain.animalgestione.premium_lifetime"
    
    // 互換性のためのダミー変数
    @Published var products: [SKProduct] = []
    @Published var purchasedProducts: [String] = []
    @Published var isLoading = false
    
    private var completionHandler: ((Result<Bool, Error>) -> Void)?
    
    override init() {
        super.init()
        // 古いStoreKit 1の初期化コードは削除し、StoreKit 2を使用
    }
    
    // 製品情報をリクエスト（StoreKit 2で実装）
    func requestProducts() {
        isLoading = true
        
        // StoreKit 2を使用して商品情報を取得
        Task {
            await subscriptionManager.loadProducts()
            // 互換性のためダミーの完了通知
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
            }
        }
    }
    
    // 購入を開始（StoreKit 2で実装）
    func purchase(product: SKProduct, completion: @escaping (Result<Bool, Error>) -> Void) {
        self.completionHandler = completion
        
        // StoreKit 2の実装にリダイレクト
        // 旧式のSKProductは使用せず、ID文字列に基づいてStoreKit 2の商品を探す
        Task {
            do {
                if let storeKitProduct = subscriptionManager.products.first(where: { $0.id == product.productIdentifier }) {
                    let transaction = try await subscriptionManager.purchase(storeKitProduct)
                    DispatchQueue.main.async {
                        completion(.success(transaction != nil))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "InAppPurchase", code: 1, userInfo: [NSLocalizedDescriptionKey: "製品が見つかりませんでした"])))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // 過去の購入を復元（StoreKit 2で実装）
    func restorePurchases(completion: @escaping (Result<Bool, Error>) -> Void) {
        self.completionHandler = completion
        
        // StoreKit 2の実装にリダイレクト
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                
                // 復元後にプレミアムステータス通知を送信
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("PremiumStatusChanged"), object: nil)
                    self.objectWillChange.send()
                    completion(.success(true))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // 広告削除オプションを購入しているかどうか（StoreKit 2を使用）
    func hasRemoveAdsPurchased() -> Bool {
        // ディレクトにSubscriptionManagerに委譲
        return subscriptionManager.hasRemoveAdsPurchased()
    }
    
    // 無料版の動物登録数上限
    static let freeUserAnimalLimit = 3
    
    // 動物登録数の上限を超えて登録できるかどうか（StoreKit 2を使用）
    func canRegisterMoreAnimals(currentCount: Int) -> Bool {
        // ディレクトにSubscriptionManagerに委譲
        return subscriptionManager.canRegisterMoreAnimals(currentCount: currentCount)
    }
    
    // サブスクリプションがアクティブかどうかをチェック（StoreKit 2を使用）
    func hasActiveSubscription() -> Bool {
        // ディレクトにSubscriptionManagerに委譲
        return subscriptionManager.hasActiveSubscription
    }
    
    // サブスクリプションの有効期限を設定（互換性のため残す）
    func setSubscriptionExpiryDate(date: Date) {
        // StoreKit 2では必要ないが、互換性のために通知だけ出す
        NotificationCenter.default.post(name: Notification.Name("SubscriptionStatusChanged"), object: nil)
    }
}

// 下位互換性のためのダミー実装（StoreKit 2では不要）
extension InAppPurchaseManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // 何もしない（StoreKit 2を使用）
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        // 何もしない（StoreKit 2を使用）
    }
}

// 下位互換性のためのダミー実装（StoreKit 2では不要）
extension InAppPurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        // 何もしない（StoreKit 2を使用）
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        // 何もしない（StoreKit 2を使用）
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        // 何もしない（StoreKit 2を使用）
    }
}
