import SwiftUI
import GoogleMobileAds
import StoreKit

/// アプリ全体の広告表示を管理するシングルトンクラス
@MainActor // MainActor注釈を追加
class AdManager: ObservableObject {
    static let shared = AdManager()
    
    // 各種広告マネージャーのインスタンス
    @Published var interstitialAdManager: InterstitialAdManager
    @Published var rewardedAdManager: RewardedAdManager
    
    // アプリ内課金マネージャー（後方互換性のために古いクラスも維持）
    @Published var purchaseManager = InAppPurchaseManager.shared
    
    // 広告表示のカウンター
    @Published var tabChangeCounter: Int = 0
    
    // 初期化
    private init() {
        interstitialAdManager = InterstitialAdManager(adUnitID: AdConfig.interstitialAdUnitId)
        rewardedAdManager = RewardedAdManager(adUnitID: AdConfig.rewardedAdUnitId)
        
        // デバイス設定
        configureTestDevices()
    }
    
    // テストデバイスの設定
    private func configureTestDevices() {
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = AdConfig.testDeviceIds
    }
    
    // 広告を表示するべきかどうかを判断
    func shouldShowAds() -> Bool {
        // プレミアム機能が非表示の場合は広告の表示/非表示の判定もデバッグフラグだけで行う
        if !InAppPurchaseManager.showPremiumFeatures {
            return !purchaseManager.debugPremiumEnabled
        }
        // プレミアム機能が表示されている場合は通常の購入確認を使用
        return !purchaseManager.hasRemoveAdsPurchased()
    }
    
    // タブ変更時の広告表示ロジック
    func onTabChange() {
        guard shouldShowAds() && AdConfig.FreeUserConfig.showInterstitialAds else { return }
        
        tabChangeCounter += 1
        
        // 設定された頻度ごとにインタースティシャル広告を表示
        if tabChangeCounter >= AdConfig.interstitialAdFrequency {
            tabChangeCounter = 0
            showInterstitialAd()
        }
    }
    
    // インタースティシャル広告を表示
    func showInterstitialAd() {
        guard shouldShowAds() && AdConfig.FreeUserConfig.showInterstitialAds else { return }
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        
        if interstitialAdManager.interstitialAd != nil {
            interstitialAdManager.presentAd(from: rootViewController)
        } else {
            interstitialAdManager.loadInterstitialAd()
        }
    }
    
    // リワード広告を表示して結果を受け取る
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard shouldShowAds() && AdConfig.FreeUserConfig.showRewardedAds else {
            completion(true) // 広告非表示の場合は自動的に報酬を与える
            return
        }
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            completion(false)
            return
        }
        
        if rewardedAdManager.rewardedAd != nil {
            rewardedAdManager.presentAd(from: rootViewController) { isRewarded in
                completion(isRewarded)
            }
        } else {
            rewardedAdManager.loadRewardedAd()
            completion(false)
        }
    }
    
    // アプリ起動時に呼び出すメソッド
    func appDidLaunch() {
        if AdConfig.showInterstitialOnAppStart && shouldShowAds() {
            // 少し遅延させて起動時に広告を表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.showInterstitialAd()
            }
        }
    }
    
    // ビューの表示時など、特定のタイミングで呼び出すメソッド
    func viewDidAppear(viewName: String) {
        print("ビュー表示: \(viewName)")
        // 特定の画面でのみ広告を表示するなどの拡張が可能
    }
}
