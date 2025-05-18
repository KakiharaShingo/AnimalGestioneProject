import StoreKit
import SwiftUI

/// StoreKit 2のTransaction型を明示的に指定
typealias StoreTransaction = StoreKit.Transaction

/// 環境モード
enum SubscriptionEnvironment {
    case debug    // デバッグ環境
    case production // 本番環境
}

/// サブスクリプションと課金を管理するクラス
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // 現在の環境設定
    @Published var environment: SubscriptionEnvironment = .production {
        didSet {
            // 環境が変更されたら通知を送信
            if oldValue != environment {
                print("サブスクリプション環境を変更: \(environment == .debug ? "デバッグ" : "本番")")
                // 購入状態を更新
                Task {
                    await updatePurchasedProducts()
                }
                // UI更新通知を送信
                NotificationCenter.default.post(name: NSNotification.Name("PremiumStatusChanged"), object: nil)
            }
        }
    }
    
    // デバッグ環境用商品ID
    private let debugMonthlyID = "com.yourdomain.animalgestione.premium_monthly"
    private let debugYearlyID = "com.yourdomain.animalgestione.premium_yearly"
    private let debugLifetimeID = "com.yourdomain.animalgestione.premium_lifetime"
    
    // 本番環境用商品ID
    private let productionMonthlyID = "SerenoSystem_animalgestione.premium_monthly"
    private let productionYearlyID = "SerenoSystem_animalgestione.premium_yearly_two"
    private let productionLifetimeID = "SerenoSystem_animalgestione.premium_lifetime"
    
    // 現在の環境に基づく商品ID
    var premiumMonthlyID: String {
        return environment == .debug ? debugMonthlyID : productionMonthlyID
    }
    
    var premiumYearlyID: String {
        return environment == .debug ? debugYearlyID : productionYearlyID
    }
    
    var premiumLifetimeID: String {
        return environment == .debug ? debugLifetimeID : productionLifetimeID
    }
    
    /// デバッグモード用設定（既存のInAppPurchaseManagerから移行）
    @Published var debugPremiumEnabled = true {
        didSet {
            // 値が変更されたら通知を送信
            if oldValue != debugPremiumEnabled {
                // デバッグ用に変更内容を出力
                print("プレミアムデバッグ状態変更: \(debugPremiumEnabled ? "有効" : "無効")")
                
                // UI更新通知を送信
                NotificationCenter.default.post(name: NSNotification.Name("PremiumStatusChanged"), object: nil)
            }
        }
    }
    
    // プレミアム機能の表示/非表示を管理するフラグ
    static let showPremiumFeatures = false
    
    // 利用可能な全商品ID
    var productIDs: [String] {
        return [premiumMonthlyID, premiumYearlyID, premiumLifetimeID]
    }
    
    // 商品情報
    @Published var products: [Product] = []
    
    // 購入済み商品のID
    @Published var purchasedProductIDs: Set<String> = []
    
    // ロード状態
    @Published var isLoading = false
    @Published var loadingError: String? = nil
    
    // 購入状態の監視タスク
    private var updateListenerTask: Task<Void, Error>? = nil
    
    init() {
        // 購入状態の監視を開始
        updateListenerTask = listenForTransactions()
        
        // 起動時に商品情報と購入状態を読み込む
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    /// 環境を切り替える
    func switchEnvironment(to newEnvironment: SubscriptionEnvironment) {
        if environment != newEnvironment {
            environment = newEnvironment
            
            // 環境が変わったら商品情報を再読み込み
            Task {
                await loadProducts()
            }
        }
    }
    
    /// デバッグ用：購入履歴をクリアする
    func clearPurchasedProducts() {
        purchasedProductIDs.removeAll()
        print("全ての購入履歴をクリアしました")
        NotificationCenter.default.post(name: NSNotification.Name("PremiumStatusChanged"), object: nil)
    }
    
    /// 商品情報を読み込む
    func loadProducts() async {
        isLoading = true
        loadingError = nil
        
        do {
            // StoreKit 2 APIを使用して商品情報を取得
            let storeProducts = try await Product.products(for: productIDs)
            
            // UIの更新はメインスレッドで行う
            await MainActor.run {
                self.products = storeProducts
                self.isLoading = false
            }
            
            if storeProducts.isEmpty {
                loadingError = "利用可能な商品が見つかりませんでした"
            }
        } catch {
            await MainActor.run {
                self.loadingError = "商品情報の読み込みに失敗しました: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("商品情報の読み込みエラー: \(error)")
        }
    }
    
    /// トランザクションの監視
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // 購入取引の更新を継続的に監視
            for await result in StoreTransaction.updates {
                do {
                    let transaction = try await self.handleVerifiedTransaction(result)
                    
                    // 購入状態の更新
                    await self.updatePurchasedProducts()
                    
                    // トランザクションを完了としてマーク
                    await transaction.finish()
                } catch {
                    print("トランザクション検証エラー: \(error)")
                }
            }
        }
    }
    
    /// トランザクションの検証と処理
    private func handleVerifiedTransaction(_ result: VerificationResult<StoreTransaction>) async throws -> StoreTransaction {
        switch result {
        case .unverified(let transaction, let error):
            // 検証に失敗した場合
            print("トランザクション検証失敗: \(error)")
            throw error
        case .verified(let transaction):
            // 検証に成功した場合
            return transaction
        }
    }
    
    /// 購入済み商品の状態を更新
    func updatePurchasedProducts() async {
        // 一時的なセットを作成
        var purchasedIDs = Set<String>()
        
        // 現在の権利を確認
        for await result in StoreTransaction.currentEntitlements {
            do {
                // トランザクションの検証
                let transaction = try await handleVerifiedTransaction(result)
                
                // 有効なトランザクションを追加
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                }
            } catch {
                print("購入検証エラー: \(error)")
            }
        }
        
        // UIの更新はメインスレッドで行う
        await MainActor.run {
            self.purchasedProductIDs = purchasedIDs
        }
    }
    
    /// 商品を購入
    func purchase(_ product: Product) async throws -> StoreTransaction? {
        // 購入処理の実行
        let result = try await product.purchase()
        
        // 結果に基づいて処理
        switch result {
        case .success(let verificationResult):
            // 購入成功、トランザクションを検証
            let transaction = try await handleVerifiedTransaction(verificationResult)
            
            // 購入状態の更新
            await updatePurchasedProducts()
            
            // トランザクションを完了としてマーク
            await transaction.finish()
            
            return transaction
            
        case .userCancelled:
            // ユーザーがキャンセルした場合
            return nil
            
        case .pending:
            // 保留中（親の承認が必要など）
            return nil
            
        @unknown default:
            // 未知の状態
            return nil
        }
    }
    
    /// 購入の復元
    func restorePurchases() async throws {
        // App Storeと同期して最新の購入情報を取得
        try await StoreKit.AppStore.sync()
        
        // 購入状態の更新
        await updatePurchasedProducts()
        
        // 通知を送信してUIを更新
        DispatchQueue.main.async {
            print("サブスクリプション情報を更新しました")
            NotificationCenter.default.post(name: NSNotification.Name("PremiumStatusChanged"), object: nil)
        }
    }
    
    /// アクティブなサブスクリプションがあるか確認
    var hasActiveSubscription: Bool {
        return !purchasedProductIDs.isEmpty
    }
    
    /// 特定の商品が購入済みかどうか確認
    func isPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    /// プレミアム機能が利用可能かどうか（いずれかのプレミアム商品を購入済み）
    var isPremiumUser: Bool {
        // デバッグモードが有効な場合は、デバッグ設定を優先
        if debugPremiumEnabled && environment == .debug {
            return true
        }
        
        return isPurchased(premiumMonthlyID) || 
               isPurchased(premiumYearlyID) || 
               isPurchased(premiumLifetimeID)
    }
    
    /// デバッグ用の購入状態表示
    func printPurchaseStatus() {
        print("現在の環境: \(environment == .debug ? "デバッグ" : "本番")")
        print("現在のプレミアム状態: \(isPremiumUser ? "プレミアム" : "無料")")
        print("購入済み商品: \(purchasedProductIDs)")
    }
    
    /// 広告削除オプションを購入しているかどうか (InAppPurchaseManagerとの互換性用)
    func hasRemoveAdsPurchased() -> Bool {
        // デバッグモードが有効な場合は、デバッグ設定を優先
        if debugPremiumEnabled && environment == .debug {
            return true
        }
        return isPremiumUser
    }
    
    /// 動物登録数の上限を超えて登録できるかどうか (InAppPurchaseManagerとの互換性用)
    func canRegisterMoreAnimals(currentCount: Int) -> Bool {
        // デバッグモードが有効な場合は、デバッグ設定を優先
        if debugPremiumEnabled && environment == .debug {
            return true
        }
        
        // 購入済みまたはサブスクリプションアクティブなら制限なし
        if isPremiumUser {
            return true
        }
        
        // 無料ユーザーは制限あり
        let freeUserAnimalLimit = 3
        return currentCount < freeUserAnimalLimit
    }
}
