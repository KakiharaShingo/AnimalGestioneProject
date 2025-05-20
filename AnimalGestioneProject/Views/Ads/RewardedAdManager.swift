import SwiftUI
// 条件付きコンパイルで囲む
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
import os

// リワード広告を管理するクラス
class RewardedAdManager: NSObject, ObservableObject {
    #if canImport(GoogleMobileAds)
    @Published var rewardedAd: RewardedAd?
    #else
    @Published var rewardedAd: Any?
    #endif
    @Published var isAdLoaded = false
    @Published var isLoading = false
    @Published var lastError: Error?
    @Published var hasEarnedReward = false
    
    private let adUnitID: String
    private var loadTime: Date?
    private let logger = Logger(subsystem: "com.animalgestione", category: "RewardedAdManager")
    
    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        #if canImport(GoogleMobileAds)
        loadRewardedAd()
        #endif
    }
    
    // リワード広告を読み込む
    func loadRewardedAd() {
        guard !isLoading else {
            logger.info("広告の読み込みは既に進行中です")
            return
        }
        
        isLoading = true
        logger.info("リワード広告の読み込みを開始")
        
        #if canImport(GoogleMobileAds)
        let request = Request()
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.lastError = error
                self.isAdLoaded = false
                self.logger.error("リワード広告の読み込みに失敗: \(error.localizedDescription)")
                return
            }
            
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
            self.isAdLoaded = true
            self.loadTime = Date()
            self.logger.info("リワード広告の読み込みに成功")
            
            // 広告の表示準備が完了したら自動的に次の広告を読み込む
            self.preloadNextAd()
        }
        #else
        // ダミーの実装
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            self.isAdLoaded = true
            self.loadTime = Date()
            self.logger.info("ダミーのリワード広告の読み込みに成功")
        }
        #endif
    }
    
    private func preloadNextAd() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadRewardedAd()
        }
    }
    
    // リワード広告を表示する
    func presentAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        #if canImport(GoogleMobileAds)
        guard let ad = rewardedAd,
              let loadTime = loadTime,
              Date().timeIntervalSince(loadTime) < 3600 else {
            logger.info("広告の表示に失敗: 広告が読み込まれていないか、有効期限が切れています")
            completion(false)
            return
        }
        
        hasEarnedReward = false
        ad.present(from: viewController) { [weak self] in
            self?.hasEarnedReward = true
            completion(true)
        }
        
        self.rewardedAd = nil
        self.isAdLoaded = false
        self.loadTime = nil
        
        // 次の広告を読み込む
        loadRewardedAd()
        #else
        // ダミーの実装
        logger.info("ダミーのリワード広告を表示")
        hasEarnedReward = true
        self.rewardedAd = nil
        self.isAdLoaded = false
        self.loadTime = nil
        
        // 次の広告を読み込む
        loadRewardedAd()
        
        // 常に報酬を付与
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(true)
        }
        #endif
    }
}

// FullScreenContentDelegateプロトコルの実装
#if canImport(GoogleMobileAds)
extension RewardedAdManager: FullScreenContentDelegate {
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        logger.error("リワード広告の表示に失敗: \(error.localizedDescription)")
        lastError = error
        isAdLoaded = false
        loadRewardedAd()
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        logger.info("リワード広告が閉じられました")
        isAdLoaded = false
        loadRewardedAd()
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        logger.info("リワード広告が表示されます")
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        logger.info("リワード広告のインプレッションが記録されました")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        logger.info("リワード広告がクリックされました")
    }
}
#endif

// SwiftUIでリワード広告を表示するためのヘルパービュー
struct RewardedAdView: UIViewControllerRepresentable {
    @ObservedObject var adManager: RewardedAdManager
    var onRewardEarned: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        adManager.presentAd(from: uiViewController) { isRewarded in
            onRewardEarned(isRewarded)
        }
    }
}