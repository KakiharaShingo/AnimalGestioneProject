import SwiftUI
import UIKit
import GoogleMobileAds
import os.log

class AdRequestCreator {
    static func createRequest() -> Any {
        return Request()
    }
}

struct BannerAdView: UIViewRepresentable {
    private let adUnitID: String
    private let bannerSize: AdSize
    var onAdLoaded: ((Bool) -> Void)?
    private let logger = Logger(subsystem: "com.animalgestione", category: "BannerAdView")

    init(adUnitID: String, size: CGSize? = nil, onAdLoaded: ((Bool) -> Void)? = nil) {
        self.adUnitID = adUnitID
        self.onAdLoaded = onAdLoaded
        let size: AdSize
        if UIDevice.current.userInterfaceIdiom == .pad {
            size = AdSizeLeaderboard
        } else {
            size = AdSizeBanner
        }
        self.bannerSize = size
        logger.info("広告を初期化: \(adUnitID), サイズ: \(size.size.width)x\(size.size.height)")
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

        let bannerView = BannerView(adSize: bannerSize)
        bannerView.adUnitID = adUnitID
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let request = AdRequestCreator.createRequest() as? Request {
                bannerView.load(request)
                self.logger.info("🚀 バナー広告読み込み開始: \(self.adUnitID)")
            } else {
                self.logger.error("❗️ リクエストの作成に失敗しました")
            }
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

    func updateUIView(_ uiView: UIView, context: Context) {}

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

            let retryDelay: TimeInterval
            switch nserror.code {
            case -1005:
                retryDelay = 10.0
            case -1009:
                retryDelay = 30.0
            default:
                retryDelay = 5.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                self.logger.info("🔄 \(Int(retryDelay))秒後の広告再読み込み試行")
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

struct BannerAdView_Previews: PreviewProvider {
    static var previews: some View {
        BannerAdView(adUnitID: "ca-app-pub-3940256099942544/2934735716")
            .frame(height: 50)
            .previewLayout(.sizeThatFits)
    }
}
