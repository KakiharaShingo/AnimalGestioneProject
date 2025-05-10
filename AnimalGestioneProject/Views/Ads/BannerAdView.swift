import SwiftUI
import GoogleMobileAds
import UIKit

// バナー広告表示用のSwiftUIラッパー
struct BannerAdView: UIViewRepresentable {
    var adUnitID: String
    var adSize: GADAdSize
    
    init(adUnitID: String, adSize: GADAdSize = GADAdSizeBanner) {
        self.adUnitID = adUnitID
        self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        
        // デバイスの最上部で実行中のルートビューコントローラを取得
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        // 広告のロード
        bannerView.load(GADRequest())
        
        // デリゲートを設定
        bannerView.delegate = context.coordinator
        
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // ビューが更新されたときに追加の処理が必要な場合はここに記述
    }
    
    // コーディネーターを作成してデリゲートを処理
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // GADBannerViewDelegateの処理を担当するコーディネータークラス
    class Coordinator: NSObject, GADBannerViewDelegate {
        var parent: BannerAdView
        
        init(_ parent: BannerAdView) {
            self.parent = parent
        }
        
        // 広告が読み込まれたとき
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("広告が読み込まれました")
        }
        
        // 広告の読み込みに失敗したとき
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("広告の読み込みに失敗しました: \(error.localizedDescription)")
        }
        
        // 広告がクリックされたとき
        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
            print("広告がインプレッションを記録しました")
        }
        
        // 広告がスクリーンを覆うコンテンツを表示するとき
        func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
            print("広告がスクリーンを表示します")
        }
        
        // 広告が閉じられたとき
        func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
            print("広告が閉じられました")
        }
    }
}

// アダプティブバナー用の拡張機能
extension BannerAdView {
    static func adaptiveBanner(width: CGFloat) -> GADAdSize {
        return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
    }
}

// テスト用のプレビュー
struct BannerAdView_Previews: PreviewProvider {
    static var previews: some View {
        // テスト用のAdMobバナー広告ID
        BannerAdView(adUnitID: "ca-app-pub-3940256099942544/2934735716")
            .frame(height: 50)
    }
}
