import SwiftUI
import StoreKit

@MainActor
class PremiumSubscriptionViewModel: ObservableObject {
    let subscriptionManager: SubscriptionManager
    
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var purchasingProduct: String? = nil
    @Published var errorMessage: String? = nil
    
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    init(subscriptionManager: SubscriptionManager = .shared) {
        self.subscriptionManager = subscriptionManager
    }
    
    /// 商品情報を読み込む
    func loadProducts() async {
        // 既に読み込み済みなら処理しない
        if !products.isEmpty {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // SubscriptionManagerから商品情報を更新させる
            await subscriptionManager.loadProducts()
            
            // 商品情報を取得してソート
            self.products = sortProducts(subscriptionManager.products)
            self.isLoading = false
            
            if products.isEmpty {
                self.errorMessage = "利用可能な商品が見つかりませんでした"
            }
        } catch {
            self.errorMessage = "商品情報の読み込みに失敗しました"
            self.isLoading = false
            print("商品情報の読み込みエラー: \(error)")
        }
    }
    
    // 購入ボタンが押されたときの処理
    func startPurchase(_ product: Product) {
        Task {
            await purchase(product)
        }
    }
    
    // 復元ボタンが押されたときの処理
    func startRestore() {
        Task {
            await restorePurchases()
        }
    }
    
    /// 商品の購入処理
    func purchase(_ product: Product) async {
        isPurchasing = true
        purchasingProduct = product.id
        
        do {
            // 商品を購入
            let transaction = try await subscriptionManager.purchase(product)
            
            if transaction != nil {
                // 購入成功
                alertMessage = "ご購入ありがとうございます！プレミアム機能がご利用いただけます。"
                showAlert = true
                
                // 購入後に即座に親コンポーネントに通知
                // 購入完了を通知する
                NotificationCenter.default.post(name: NSNotification.Name("PremiumPurchaseCompleted"), object: nil)
                
                // 画面を閉じる通知も送信
                NotificationCenter.default.post(name: NSNotification.Name("DismissPremiumView"), object: nil)
            }
            isPurchasing = false
            purchasingProduct = nil
        } catch {
            alertMessage = "購入処理中にエラーが発生しました"
            showAlert = true
            isPurchasing = false
            purchasingProduct = nil
        }
    }
    
    /// 購入の復元処理
    func restorePurchases() async {
        isPurchasing = true
        
        do {
            // 購入を復元
            try await subscriptionManager.restorePurchases()
            
            if subscriptionManager.hasActiveSubscription {
                alertMessage = "購入が復元されました！"
                // 復元成功時にプレミアムステータス変更通知を送信
                NotificationCenter.default.post(name: NSNotification.Name("PremiumPurchaseCompleted"), object: nil)
                // 画面を閉じる通知も送信
                NotificationCenter.default.post(name: NSNotification.Name("DismissPremiumView"), object: nil)
            } else {
                alertMessage = "復元できる購入はありませんでした。"
            }
            showAlert = true
            isPurchasing = false
        } catch {
            alertMessage = "購入の復元中にエラーが発生しました"
            showAlert = true
            isPurchasing = false
        }
    }
    
    /// 商品を適切な順序に並べ替え
    private func sortProducts(_ products: [Product]) -> [Product] {
        // 最初に一時購入、次に年間サブスク、最後に月間サブスクの順序で表示
        return products.sorted { product1, product2 in
            if product1.id.contains("lifetime") {
                return true
            } else if product2.id.contains("lifetime") {
                return false
            } else if product1.id.contains("yearly") {
                return true
            } else if product2.id.contains("yearly") {
                return false
            } else {
                return true
            }
        }
    }
}
