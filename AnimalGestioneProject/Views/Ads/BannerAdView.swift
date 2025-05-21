import SwiftUI
import UIKit
import GoogleMobileAds
import os.log

// 型識別のためのカスタムクラス
class AdRequestCreator {
    static func createRequest() -> Any {
        return Request()
    }
}

// バナー広告表示用のSwiftUIラッパー
struct BannerAdView: UIViewRepresentable {
    private let adUnitID: String
    private var bannerSize: AdSize
    var onAdLoaded: ((Bool) -> Void)?
    private let logger = Logger(subsystem: "com.animalgestione", category: "BannerAdView")
    
    init(adUnitID: String, size: CGSize? = nil, onAdLoaded: ((Bool) -> Void)? = nil) {
        self.adUnitID = adUnitID
        self.onAdLoaded = onAdLoaded
        
        // デフォルトサイズの設定
        if let customSize = size {
            self.bannerSize = adSizeFor(cgSize: customSize)
        } else {
            let screenWidth = UIScreen.main.bounds.width
            self.bannerSize = currentOrientationAnchoredAdaptiveBanner(width: screenWidth)
        }
        
        logger.info("広告を初期化: \(adUnitID)")
    }
    
    func makeUIView(context: Context) -> UIView {
        logger.info("💡 BannerAdView: makeUIViewを開始")
        
        let containerView = UIView(frame: CGRect(origin: .zero, size: bannerSize.size))
        containerView.backgroundColor = .clear
        
        if adUnitID.contains("ca-app-pub-3940256099942544") {
            logger.info("✅ テスト広告IDを使用中")
        } else {
            logger.info("⚠️ 本番広告IDを使用中")
        }

        let testAdUnitID = "ca-app-pub-3940256099942544/2934735716"
        logger.info("📱 テスト広告ID: \(testAdUnitID)")
        
        let bannerView = BannerView(adSize: bannerSize)
        bannerView.adUnitID = testAdUnitID
        bannerView.delegate = context.coordinator
        bannerView.rootViewController = findRootViewController()
        containerView.addSubview(bannerView)
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            bannerView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            bannerView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            bannerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        if let request = AdRequestCreator.createRequest() as? Request {
            bannerView.load(request)
            logger.info("🚀 バナー広告読み込み開始: \(testAdUnitID)")
        } else {
            logger.error("❗️ リクエストの作成に失敗しました")
        }
        
        logger.info("📐 広告ビューの準備完了 - サイズ: \(String(describing: bannerView.frame.size))")
        
        return containerView
    }
    
    private func findRootViewController() -> UIViewController {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            logger.info("✅ rootViewController設定成功: \(type(of: rootVC))")
            return rootVC
        }
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
           let rootVC = keyWindow.rootViewController {
            logger.info("✅ フォールバック: keyWindowからrootViewControllerを取得: \(type(of: rootVC))")
            return rootVC
        }
        if let anyWindow = UIApplication.shared.windows.first,
           let rootVC = anyWindow.rootViewController {
            logger.info("✅ フォールバック: 最初のウィンドウからrootViewControllerを取得")
            return rootVC
        }
        
        logger.error("❌ エラー: どの方法でもrootViewControllerを取得できませんでした")
        return UIViewController()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新処理がある場合に記述
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BannerViewDelegate {
        var parent: BannerAdView
        private let logger = Logger(subsystem: "com.animalgestione", category: "BannerAdCoordinator")
        
        init(_ parent: BannerAdView) {
            self.parent = parent
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            logger.info("✅ バナー広告の読み込みに成功しました: サイズ=\(String(describing: bannerView.adSize))")
            parent.onAdLoaded?(true)
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            logger.error("❌ バナー広告の読み込みに失敗しました: \(error.localizedDescription)")
            parent.onAdLoaded?(false)
            
            let nserror = error as NSError
            logger.error("📊 エラーコード: \(nserror.code), ドメイン: \(nserror.domain)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.logger.info("🔄 5秒後の広告再読み込み試行")
                if let newRequest = AdRequestCreator.createRequest() as? Request {
                    bannerView.load(newRequest)
                }
            }
        }
        
        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            logger.info("🔍 バナー広告が画面を覆います")
        }
        
        func bannerViewWillDismissScreen(_ bannerView: BannerView) {
            logger.info("🔍 バナー広告が閉じられます")
        }
        
        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            logger.info("🔍 バナー広告が閉じられました")
        }
    }
}

// サイズ取得の補助関数
extension BannerAdView {
    static func getAdSize(width: CGFloat? = nil) -> CGSize {
        let screenWidth = width ?? UIScreen.main.bounds.width
        if UIDevice.current.userInterfaceIdiom == .pad {
            return CGSize(width: min(728, screenWidth), height: 90)
        } else {
            return CGSize(width: min(320, screenWidth), height: 50)
        }
    }
}

struct BannerAdView_Previews: PreviewProvider {
    static var previews: some View {
        BannerAdView(adUnitID: "ca-app-pub-3940256099942544/2934735716")
            .frame(height: 50)
            .previewLayout(.sizeThatFits)
    }
}
