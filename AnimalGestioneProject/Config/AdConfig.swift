import Foundation

/// 広告設定を管理する構造体
struct AdConfig {
    // テスト用のIDか本番用のIDかを切り替えるフラグ
    static let useTestIds = true  // テスト用IDを使用するように変更
    
    // バナー広告ID
    static var bannerAdUnitId: String {
        if useTestIds {
            return "ca-app-pub-3940256099942544/2934735716" // テスト用ID
        } else {
            return "ca-app-pub-7155393284008150/7195286081" // 本番用IDに置き換えてください
        }
    }
    
    // インタースティシャル広告ID
    static var interstitialAdUnitId: String {
        if useTestIds {
            return "ca-app-pub-3940256099942544/4411468910" // テスト用ID
        } else {
            return "ca-app-pub-7155393284008150/4668969752" // 本番用IDに置き換えてください
        }
    }
    
    // リワード広告ID
    static var rewardedAdUnitId: String {
        if useTestIds {
            return "ca-app-pub-3940256099942544/1712485313" // テスト用ID
        } else {
            return "ca-app-pub-7155393284008150/4946211470" // 本番用IDに置き換えてください
        }
    }
    
    // 広告表示の頻度設定（タブ切り替え回数）
    static let interstitialAdFrequency = 5 // 5回タブを切り替えるごとに表示
    
    // アプリ起動時に広告を表示するかどうか
    static let showInterstitialOnAppStart = false
    
    // 無料ユーザーに対する広告表示の設定
    struct FreeUserConfig {
        // バナー広告を表示するかどうか
        static let showBannerAds = true
        
        // インタースティシャル広告を表示するかどうか
        static let showInterstitialAds = true
        
        // リワード広告を表示するかどうか
        static let showRewardedAds = true
    }
    
    // テスト端末のIDリスト（AdMobコンソールで確認できます）
    static let testDeviceIds: [String] = [
        "2077ef9a63d2b398840261c8221a0c9b", // 開発用iPhone
        "kGADSimulatorID" // シミュレータ用
    ]
}
