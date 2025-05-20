import SwiftUI
import GoogleMobileAds
import os

// インタースティシャル（全画面）広告を管理するクラス
class InterstitialAdManager: NSObject, ObservableObject {
    @Published var interstitialAd: InterstitialAd?
    @Published var isAdLoaded = false
    @Published var isLoading = false
    @Published var lastError: Error?
    
    private let adUnitID: String
    private var loadTime: Date?
    private let logger = Logger(subsystem: "com.animalgestione", category: "InterstitialAdManager")
    
    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        loadInterstitialAd()
    }
    
    // 広告を読み込む
    func loadInterstitialAd() {
        guard !isLoading else {
            logger.info("広告の読み込みは既に進行中です")
            return
        }
        
        isLoading = true
        logger.info("インタースティシャル広告の読み込みを開始: \(self.adUnitID)")
        
        let request = Request()
        InterstitialAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.lastError = error
                self.isAdLoaded = false
                self.logger.error("インタースティシャル広告の読み込みに失敗: \(error.localizedDescription)")
                return
            }
            
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.isAdLoaded = true
            self.loadTime = Date()
            self.logger.info("インタースティシャル広告の読み込みに成功")
            
            // 広告の表示準備が完了したら自動的に次の広告を読み込む
            self.preloadNextAd()
        }
    }
    
    private func preloadNextAd() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadInterstitialAd()
        }
    }
    
    // 広告を表示する
    func showAd(from viewController: UIViewController) async throws {
        guard let ad = interstitialAd,
              let loadTime = loadTime,
              Date().timeIntervalSince(loadTime) < 3600 else {
            logger.info("広告の表示に失敗: 広告が読み込まれていないか、有効期限が切れています")
            throw NSError(domain: "com.animalgestione", code: 1, userInfo: [NSLocalizedDescriptionKey: "広告が読み込まれていないか、有効期限が切れています"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                ad.present(from: viewController)
                self.interstitialAd = nil
                self.isAdLoaded = false
                self.loadTime = nil
                
                // 次の広告を読み込む
                self.loadInterstitialAd()
                
                continuation.resume()
            }
        }
    }
}

// FullScreenContentDelegateプロトコルの実装
extension InterstitialAdManager: FullScreenContentDelegate {
    // 広告の表示に失敗したとき
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        logger.error("インタースティシャル広告の表示に失敗: \(error.localizedDescription)")
        lastError = error
        isAdLoaded = false
        loadInterstitialAd()
    }
    
    // 広告が閉じられたとき
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        logger.info("インタースティシャル広告が閉じられました")
        isAdLoaded = false
        loadInterstitialAd()
    }
    
    // 新しいデリゲートメソッド（古いadDidPresentFullScreenContentの代替）
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("広告が表示されます")
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        logger.info("インタースティシャル広告のインプレッションが記録されました")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        logger.info("インタースティシャル広告がクリックされました")
    }
}

// SwiftUIでインタースティシャル広告を表示するためのヘルパービュー
struct InterstitialAdView: UIViewControllerRepresentable {
    @ObservedObject var adManager: InterstitialAdManager
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        Task {
            do {
                try await adManager.showAd(from: uiViewController)
            } catch {
                print("広告の表示に失敗しました: \(error.localizedDescription)")
            }
        }
    }
}