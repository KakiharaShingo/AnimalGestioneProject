import SwiftUI
import UIKit
import GoogleMobileAds
import os.log

// 型識別のためのカスタムクラス
class AdRequestCreator {
    static func createRequest() -> Any {
        // GoogleMobileAds.Request()を返す
        return Request()
    }
}

// バナー広告表示用のSwiftUIラッパー
struct BannerAdView: UIViewRepresentable {
    private let adUnitID: String
    private var bannerSize: CGSize
    var onAdLoaded: ((Bool) -> Void)?
    private let logger = Logger(subsystem: "com.animalgestione", category: "BannerAdView")
    
    init(adUnitID: String, size: CGSize? = nil, onAdLoaded: ((Bool) -> Void)? = nil) {
        self.adUnitID = adUnitID
        self.onAdLoaded = onAdLoaded
        
        // デフォルトサイズの設定
        if let customSize = size {
            self.bannerSize = customSize
        } else {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPadの場合
                self.bannerSize = CGSize(width: 728, height: 90)
            } else {
                // iPhoneの場合
                self.bannerSize = CGSize(width: 320, height: 50)
            }
        }
        
        logger.info("広告を初期化: \(adUnitID)")
    }
    
    // UIViewの作成
    func makeUIView(context: Context) -> UIView {
        logger.info("💡 BannerAdView: makeUIViewを開始")
        
        // コンテナビューを作成
        let containerView = UIView(frame: CGRect(origin: .zero, size: bannerSize))
        containerView.backgroundColor = .clear
        
        // テスト広告IDかどうかをチェック
        if adUnitID.contains("ca-app-pub-3940256099942544") {
            logger.info("✅ テスト広告IDを使用中")
        } else {
            logger.info("⚠️ 本番広告IDを使用中")
        }
        
        // 固定のテスト広告IDを使用
        let testAdUnitID = "ca-app-pub-3940256099942544/2934735716"
        logger.info("📱 テスト広告ID: \(testAdUnitID)")
        
        // 広告サイズの決定
        let adSize = getBannerAdSize()
        
        // バナービューの作成と設定
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = testAdUnitID
        bannerView.delegate = context.coordinator
        bannerView.rootViewController = findRootViewController()
        containerView.addSubview(bannerView)
        
        // バナービューをコンテナに追加
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            bannerView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            bannerView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            bannerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // 広告リクエストを作成して読み込み
        if let request = AdRequestCreator.createRequest() as? Request {
            bannerView.load(request)
            logger.info("🚀 バナー広告読み込み開始: \(testAdUnitID)")
        } else {
            logger.error("❗️ リクエストの作成に失敗しました")
        }
        
        // デバッグ情報を出力
        logger.info("📐 広告ビューの準備完了 - サイズ: \(String(describing: bannerView.frame.size))")
        
        return containerView
    }
    
    // 適切なAdSizeを取得
    private func getBannerAdSize() -> AdSize {
        if bannerSize.width >= 728 && bannerSize.height >= 90 {
            logger.info("📏 AdSizeLeaderboardを使用")
            return AdSizeLeaderboard
        } else if bannerSize.width >= 468 && bannerSize.height >= 60 {
            logger.info("📏 AdSizeFullBannerを使用")
            return AdSizeFullBanner
        } else if bannerSize.width >= 320 && bannerSize.height >= 100 {
            logger.info("📏 AdSizeLargeBannerを使用")
            return AdSizeLargeBanner
        } else {
            logger.info("📏 AdSizeBannerを使用")
            return AdSizeBanner
        }
    }
    
    // rootViewControllerを見つける
    private func findRootViewController() -> UIViewController {
        // 最初の試み: UIWindowSceneから取得
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            logger.info("✅ rootViewController設定成功: \(type(of: rootVC))")
            return rootVC
        }
        
        // 第2の試み: keyWindowから取得
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
           let rootVC = keyWindow.rootViewController {
            logger.info("✅ フォールバック: keyWindowからrootViewControllerを取得: \(type(of: rootVC))")
            return rootVC
        }
        
        // 第3の試み: 最初のウィンドウから取得
        if let anyWindow = UIApplication.shared.windows.first,
           let rootVC = anyWindow.rootViewController {
            logger.info("✅ フォールバック: 最初のウィンドウからrootViewControllerを取得")
            return rootVC
        }
        
        // 最終手段: 新しいUIViewControllerを作成
        logger.error("❌ エラー: どの方法でもrootViewControllerを取得できませんでした")
        let fallbackVC = UIViewController()
        logger.info("⚠️ 新しいUIViewControllerをrootViewControllerとして使用")
        return fallbackVC
    }
    
    // UIViewの更新
    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新が必要な場合はここに実装
    }
    
    // コーディネーターの作成
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // コーディネータークラス
    class Coordinator: NSObject, BannerViewDelegate {
        var parent: BannerAdView
        private let logger = Logger(subsystem: "com.animalgestione", category: "BannerAdCoordinator")
        
        init(_ parent: BannerAdView) {
            self.parent = parent
        }
        
        // 広告が読み込まれた
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            logger.info("✅ バナー広告の読み込みに成功しました: サイズ=\(String(describing: bannerView.adSize))")
            parent.onAdLoaded?(true)
        }
        
        // 広告の読み込みに失敗した
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            logger.error("❌ バナー広告の読み込みに失敗しました: \(error.localizedDescription)")
            parent.onAdLoaded?(false)
            
            // エラーの詳細を表示
            let nserror = error as NSError
            logger.error("📊 エラーコード: \(nserror.code), ドメイン: \(nserror.domain)")
            
            // 5秒後に再試行
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.logger.info("🔄 5秒後の広告再読み込み試行")
                if let newRequest = AdRequestCreator.createRequest() as? Request {
                    bannerView.load(newRequest)
                }
            }
        }
        
        // 広告が画面を覆う場合の処理
        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            logger.info("🔍 バナー広告が画面を覆います")
        }
        
        // 広告が閉じられる場合の処理
        func bannerViewWillDismissScreen(_ bannerView: BannerView) {
            logger.info("🔍 バナー広告が閉じられます")
        }
        
        // 広告が閉じられた場合の処理
        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            logger.info("🔍 バナー広告が閉じられました")
        }
    }
}

// デバイスタイプの判定用拡張
extension BannerAdView {
    // デバイスタイプに応じた適切なサイズを計算
    static func getAdSize(width: CGFloat? = nil) -> CGSize {
        let screenWidth = width ?? UIScreen.main.bounds.width
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPadの場合
            return CGSize(width: min(728, screenWidth), height: 90)
        } else {
            // iPhoneの場合
            return CGSize(width: min(320, screenWidth), height: 50)
        }
    }
}

// テスト用のプレビュー
struct BannerAdView_Previews: PreviewProvider {
    static var previews: some View {
        BannerAdView(adUnitID: "ca-app-pub-3940256099942544/2934735716")
            .frame(height: 50)
            .previewLayout(.sizeThatFits)
    }
}
