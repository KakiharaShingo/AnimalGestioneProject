import Foundation
import StoreKit

/// アプリ内課金を管理するクラス
class InAppPurchaseManager: NSObject, ObservableObject {
    static let shared = InAppPurchaseManager()
    
    // 利用可能な商品のID
    let removeAdsProductID = "com.yourdomain.animalgestione.removeads"
    
    @Published var products: [SKProduct] = []
    @Published var purchasedProducts: [String] = []
    @Published var isLoading = false
    
    private var productRequest: SKProductsRequest?
    private var completionHandler: ((Result<Bool, Error>) -> Void)?
    
    override init() {
        super.init()
        
        // トランザクションオブザーバーを設定
        SKPaymentQueue.default().add(self)
        
        // 過去の購入を復元
        loadPurchasedProducts()
    }
    
    // 過去の購入を読み込む
    private func loadPurchasedProducts() {
        if let savedProducts = UserDefaults.standard.array(forKey: "PurchasedProducts") as? [String] {
            purchasedProducts = savedProducts
        }
    }
    
    // 購入を保存する
    private func savePurchasedProducts() {
        UserDefaults.standard.set(purchasedProducts, forKey: "PurchasedProducts")
    }
    
    // 製品情報をリクエスト
    func requestProducts() {
        isLoading = true
        let productIDs = Set([removeAdsProductID])
        productRequest = SKProductsRequest(productIdentifiers: productIDs)
        productRequest?.delegate = self
        productRequest?.start()
    }
    
    // 購入を開始
    func purchase(product: SKProduct, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard SKPaymentQueue.canMakePayments() else {
            completion(.failure(NSError(domain: "InAppPurchase", code: 0, userInfo: [NSLocalizedDescriptionKey: "このデバイスでは購入できません"])))
            return
        }
        
        self.completionHandler = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    // 過去の購入を復元
    func restorePurchases(completion: @escaping (Result<Bool, Error>) -> Void) {
        self.completionHandler = completion
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // 広告削除オプションを購入しているかどうか
    func hasRemoveAdsPurchased() -> Bool {
        return purchasedProducts.contains(removeAdsProductID)
    }
}

// SKProductsRequestDelegateプロトコルの実装
extension InAppPurchaseManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async { [weak self] in
            self?.products = response.products
            self?.isLoading = false
            
            if !response.invalidProductIdentifiers.isEmpty {
                print("無効な製品ID: \(response.invalidProductIdentifiers)")
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            print("製品リクエストに失敗しました: \(error.localizedDescription)")
        }
    }
}

// SKPaymentTransactionObserverプロトコルの実装
extension InAppPurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchasedTransaction(transaction)
            case .restored:
                handleRestoredTransaction(transaction)
            case .failed:
                handleFailedTransaction(transaction)
            case .deferred, .purchasing:
                // これらの状態は特に何もする必要がありません
                break
            @unknown default:
                break
            }
        }
    }
    
    private func handlePurchasedTransaction(_ transaction: SKPaymentTransaction) {
        let productID = transaction.payment.productIdentifier
        
        // 購入リストに追加
        if !purchasedProducts.contains(productID) {
            purchasedProducts.append(productID)
            savePurchasedProducts()
        }
        
        // トランザクションを完了としてマーク
        SKPaymentQueue.default().finishTransaction(transaction)
        
        // 完了ハンドラーを呼び出す
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler?(.success(true))
            self?.completionHandler = nil
        }
    }
    
    private func handleRestoredTransaction(_ transaction: SKPaymentTransaction) {
        if let productID = transaction.original?.payment.productIdentifier {
            // 購入リストに追加
            if !purchasedProducts.contains(productID) {
                purchasedProducts.append(productID)
                savePurchasedProducts()
            }
        }
        
        // トランザクションを完了としてマーク
        SKPaymentQueue.default().finishTransaction(transaction)
        
        // 完了ハンドラーを呼び出す
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler?(.success(true))
            self?.completionHandler = nil
        }
    }
    
    private func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        // エラーがあればログに出力
        if let error = transaction.error {
            print("トランザクションに失敗しました: \(error.localizedDescription)")
        }
        
        // トランザクションを完了としてマーク
        SKPaymentQueue.default().finishTransaction(transaction)
        
        // 完了ハンドラーを呼び出す
        DispatchQueue.main.async { [weak self] in
            if let error = transaction.error {
                self?.completionHandler?(.failure(error))
            } else {
                self?.completionHandler?(.failure(NSError(domain: "InAppPurchase", code: 0, userInfo: [NSLocalizedDescriptionKey: "購入に失敗しました"])))
            }
            self?.completionHandler = nil
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler?(.success(true))
            self?.completionHandler = nil
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler?(.failure(error))
            self?.completionHandler = nil
        }
    }
}
