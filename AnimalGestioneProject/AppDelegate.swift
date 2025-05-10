// インポート
import Foundation
import UIKit
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // AdMobアプリケーションIDはInfo.plistに設定済み
        
        // AdMobリクエスト設定の初期化
        let requestConfiguration = GADMobileAds.sharedInstance().requestConfiguration
        
        // テストデバイスの設定
        requestConfiguration.testDeviceIdentifiers = AdConfig.testDeviceIds
        
        // 子ども向けコンテンツの設定（ペットアプリなので一般向け）
        requestConfiguration.tagForChildDirectedTreatment = NSNumber(value: false)
        
        // AdMobを初期化
        GADMobileAds.sharedInstance().start(completionHandler: { status in
            print("AdMob初期化ステータス: ", status.adapterStatusesByClassName)
        })
        
        // iOS 14以降でトラッキング許可リクエストを遅延実行（Appleのガイドラインに従う）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestTrackingAuthorization()
        }
        
        // InAppPurchaseManagerとAdManagerの初期化
        // これらはシングルトンパターンを使用しているので参照するだけでOK
        _ = InAppPurchaseManager.shared
        _ = AdManager.shared
        
        // 通知の設定
        setupNotificationCategories()
        
        return true
    }
    
    // トラッキング許可リクエスト処理
    private func requestTrackingAuthorization() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    // トラッキング許可が与えられた場合、IDFA にアクセス可能
                    print("トラッキング許可: 許可されました")
                    // トラッキングIDが利用可能になったので広告IDをリフレッシュ
                    self.refreshAdRequest()
                case .denied:
                    // トラッキングが明示的に拒否された
                    print("トラッキング許可: 拒否されました")
                case .notDetermined:
                    // ユーザーが選択していない
                    print("トラッキング許可: まだ選択されていません")
                case .restricted:
                    // デバイスの制限によりトラッキングが不可能
                    print("トラッキング許可: 制限されています")
                @unknown default:
                    print("トラッキング許可: 不明なステータス")
                }
            }
        }
    }
    
    // 広告リクエストを更新する
    private func refreshAdRequest() {
        // 広告マネージャーを再初期化
        DispatchQueue.main.async {
            // 広告をリロード
            AdManager.shared.interstitialAdManager.loadInterstitialAd()
            AdManager.shared.rewardedAdManager.loadRewardedAd()
        }
    }
    
    // 通知カテゴリを設定
    private func setupNotificationCategories() {
        // 通知センターの取得
        let notificationCenter = UNUserNotificationCenter.current()
        
        // 生理周期通知カテゴリ
        let physiologicalCategory = UNNotificationCategory(
            identifier: "PHYSIOLOGICAL",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // 健康診断通知カテゴリ
        let checkupCategory = UNNotificationCategory(
            identifier: "CHECKUP",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // ワクチン接種通知カテゴリ
        let vaccineCategory = UNNotificationCategory(
            identifier: "VACCINE",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // 一般イベント通知カテゴリ
        let eventCategory = UNNotificationCategory(
            identifier: "EVENT",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // カテゴリを設定
        notificationCenter.setNotificationCategories([physiologicalCategory, checkupCategory, vaccineCategory, eventCategory])
    }
}