import SwiftUI
import GoogleMobileAds
import UIKit
import Network

// バナー広告表示用のSwiftUIラッパー
struct BannerAdView: UIViewRepresentable {
    var adUnitID: String
    var adSize: GADAdSize
    var onAdLoaded: ((Bool) -> Void)? // 広告の読み込み状態を通知するコールバック
    
    // 広告ビューのサイズを保持するプロパティを追加
    private let bannerWidth: CGFloat
    private let bannerHeight: CGFloat
    
    init(adUnitID: String, adSize: GADAdSize? = nil, onAdLoaded: ((Bool) -> Void)? = nil) {
        self.adUnitID = adUnitID
        self.onAdLoaded = onAdLoaded
        
        // デバイスタイプに応じて適切な広告サイズを選択
        if let customAdSize = adSize {
            self.adSize = customAdSize
            self.bannerWidth = customAdSize.size.width
            self.bannerHeight = customAdSize.size.height
        } else {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPadの場合はリーダーボードサイズ（728x90）を使用
                self.adSize = GADAdSizeLeaderboard
                self.bannerWidth = 728
                self.bannerHeight = 90
            } else {
                // iPhoneの場合は標準バナーサイズ（320x50）を使用
                self.adSize = GADAdSizeBanner
                self.bannerWidth = 320
                self.bannerHeight = 50
            }
        }
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        
        // iPad用の広告サイズを設定
        if UIDevice.current.userInterfaceIdiom == .pad {
            bannerView.adSize = GADAdSizeLeaderboard
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
            
            // 広告ビューのフレームを明示的に設定
            let screenWidth = UIScreen.main.bounds.width
            let xPosition = (screenWidth - bannerWidth) / 2
            bannerView.frame = CGRect(x: xPosition, y: 0, width: bannerWidth, height: bannerHeight)
        } else if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        // 広告のロード
        let request = GADRequest()
        
        // ネットワーク接続の監視を設定
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                // 接続が確立されたら少し待ってから広告を読み込む
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // 接続タイプに応じた処理
                    if path.usesInterfaceType(.wifi) {
                        bannerView.load(request)
                    } else if path.usesInterfaceType(.cellular) {
                        // モバイルデータ通信の場合は少し待ってから読み込み
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            let newRequest = GADRequest()
                            bannerView.load(newRequest)
                        }
                    } else {
                        bannerView.load(request)
                    }
                }
            } else {
                // 接続が利用できない場合は少し待ってから再試行
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if path.status == .satisfied {
                        let newRequest = GADRequest()
                        bannerView.load(newRequest)
                    }
                }
            }
        }
        
        // 監視を開始
        monitor.start(queue: queue)
        
        // デリゲートを設定
        bannerView.delegate = context.coordinator
        
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 更新時にフレームが変更されないようにする
        let screenWidth = UIScreen.main.bounds.width
        let xPosition = (screenWidth - bannerWidth) / 2
        uiView.frame = CGRect(x: xPosition, y: 0, width: bannerWidth, height: bannerHeight)
    }
    
    // コーディネーターを作成してデリゲートを処理
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // GADBannerViewDelegateの処理を担当するコーディネータークラス
    class Coordinator: NSObject, GADBannerViewDelegate {
        var parent: BannerAdView
        private var retryCount = 0
        private let maxRetries = 3
        private var lastErrorTime: Date?
        private let retryInterval: TimeInterval = 5.0
        private var isRetrying = false
        
        init(_ parent: BannerAdView) {
            self.parent = parent
            super.init()
        }
        
        // 広告が読み込まれたとき
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            retryCount = 0
            lastErrorTime = nil
            isRetrying = false
            parent.onAdLoaded?(true)
        }
        
        // 広告の読み込みに失敗したとき
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            let nsError = error as NSError
            let currentTime = Date()
            
            // エラーの種類に応じて処理を分岐
            if nsError.domain == "com.google.admob" && nsError.code == 2 {
                // 既に再試行中の場合は処理をスキップ
                if isRetrying {
                    return
                }
                
                // 最後のエラーから一定時間経過しているか確認
                if let lastError = lastErrorTime,
                   currentTime.timeIntervalSince(lastError) < retryInterval {
                    return
                }
                
                if retryCount < maxRetries {
                    retryCount += 1
                    lastErrorTime = currentTime
                    isRetrying = true
                    
                    // エラーの種類に応じて待機時間を調整
                    let waitTime = Double(retryCount * 2)
                    DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                        let newRequest = GADRequest()
                        bannerView.load(newRequest)
                    }
                } else {
                    retryCount = 0
                    lastErrorTime = nil
                    isRetrying = false
                }
            }
            
            parent.onAdLoaded?(false)
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
