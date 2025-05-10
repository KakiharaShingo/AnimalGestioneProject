import SwiftUI
import GoogleMobileAds

// インタースティシャル（全画面）広告を管理するクラス
class InterstitialAdManager: NSObject, ObservableObject {
    @Published var interstitialAd: GADInterstitialAd?
    private let adUnitID: String
    
    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        loadInterstitialAd()
    }
    
    // 広告を読み込む
    func loadInterstitialAd() {
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("インタースティシャル広告の読み込みに失敗しました: \(error.localizedDescription)")
                return
            }
            
            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
            print("インタースティシャル広告を読み込みました")
        }
    }
    
    // 広告を表示する
    func presentAd(from rootViewController: UIViewController) {
        if let interstitialAd = interstitialAd {
            interstitialAd.present(fromRootViewController: rootViewController)
        } else {
            print("インタースティシャル広告がまだ読み込まれていません")
            loadInterstitialAd()
        }
    }
}

// FullScreenContentDelegateプロトコルの実装
extension InterstitialAdManager: GADFullScreenContentDelegate {
    // 広告の表示に失敗したとき
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("広告の表示に失敗しました: \(error.localizedDescription)")
        loadInterstitialAd()  // 次回の準備のために再読み込み
    }
    
    // 広告が閉じられたとき
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("広告が閉じられました")
        loadInterstitialAd()  // 次回の準備のために再読み込み
    }
    
    // 新しいデリゲートメソッド（古いadDidPresentFullScreenContentの代替）
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("広告が表示されます")
    }
    
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("広告がインプレッションを記録しました")
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
        adManager.presentAd(from: uiViewController)
    }
}
