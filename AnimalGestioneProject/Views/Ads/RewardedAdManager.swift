import SwiftUI
import GoogleMobileAds

// リワード広告を管理するクラス
class RewardedAdManager: NSObject, ObservableObject {
    @Published var rewardedAd: GADRewardedAd?
    @Published var isRewardEarned: Bool = false
    @Published var isLoading: Bool = false
    private let adUnitID: String
    
    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        loadRewardedAd()
    }
    
    // リワード広告を読み込む
    func loadRewardedAd() {
        isLoading = true
        
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            self?.isLoading = false
            
            if let error = error {
                print("リワード広告の読み込みに失敗しました: \(error.localizedDescription)")
                return
            }
            
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            print("リワード広告を読み込みました")
        }
    }
    
    // リワード広告を表示する
    func presentAd(from rootViewController: UIViewController, completion: @escaping (Bool) -> Void) {
        isRewardEarned = false
        
        if let rewardedAd = rewardedAd {
            rewardedAd.present(fromRootViewController: rootViewController) { [weak self] in
                // 報酬が付与された
                self?.isRewardEarned = true
                completion(true)
            }
        } else {
            print("リワード広告がまだ読み込まれていません")
            loadRewardedAd()
            completion(false)
        }
    }
}

// GADFullScreenContentDelegateプロトコルの実装
extension RewardedAdManager: GADFullScreenContentDelegate {
    // 広告の表示に失敗したとき
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("リワード広告の表示に失敗しました: \(error.localizedDescription)")
        loadRewardedAd()  // 次回の準備のために再読み込み
    }
    
    // 広告が閉じられたとき
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("リワード広告が閉じられました")
        loadRewardedAd()  // 次回の準備のために再読み込み
    }
    
    // 新しいデリゲートメソッド（古いadDidPresentFullScreenContentの代替）
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("リワード広告が表示されます")
    }
    
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        print("リワード広告がインプレッションを記録しました")
    }
}

// SwiftUIでリワード広告を表示するためのヘルパービュー
struct RewardedAdView: UIViewControllerRepresentable {
    @ObservedObject var adManager: RewardedAdManager
    var completion: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        adManager.presentAd(from: uiViewController) { isRewarded in
            completion(isRewarded)
        }
    }
}