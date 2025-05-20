// インポート
import Foundation
import UIKit
import AdSupport
import SwiftUI
import UserNotifications
import os
import GoogleMobileAds
import Network

class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: "com.animalgestione", category: "AppDelegate")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        logger.info("AppDelegate: application(_:didFinishLaunchingWithOptions:) 開始")
        
        // デバイス情報のログ出力
        logDeviceInfo()
        
        // アプリケーションのポリシー同意状態を設定
        setConsentPolicy()
        
        // AdMobの初期化
        logger.info("GoogleMobileAds SDK初期化開始")
        
        // シミュレータIDを設定 (新しい方法と古い方法の両方を試す)
        let testDeviceIDs = ["kGADSimulatorID", "GAD_SIMULATOR_ID"]
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = testDeviceIDs
        logger.info("テストデバイス設定完了: \(testDeviceIDs)")
        
        // 子供向けコンテンツの設定 (nilを使用してunspecifiedを表現)
        MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
        logger.info("子供向けコンテンツの設定を完了")
        
        // AdMobの初期化とエラーハンドリング
        MobileAds.shared.start { [weak self] status in
            guard let self = self else { return }
            
            if let adapterStatuses = status.adapterStatusesByClassName as? [String: NSObject] {
                for (adapter, status) in adapterStatuses {
                    if let statusNum = status.value(forKey: "state") as? Int,
                       let statusDesc = status.value(forKey: "description") as? String {
                        self.logger.info("アダプター: \(adapter), 状態: \(statusNum), 説明: \(statusDesc)")
                    }
                }
            }
            
            self.logger.info("GoogleMobileAds初期化完了")
            
            // すべてのアダプターが正常に初期化されたかチェック
            let allInitialized = status.adapterStatusesByClassName.values.allSatisfy { status in
                status.state == .ready
            }
            
            self.logger.info("アダプターの初期化: \(allInitialized ? "すべて完了" : "一部失敗")")
            
            // 初期化後、広告のプリロードを行う
            DispatchQueue.main.async {
                self.logger.info("広告プリロード開始")
                AdManager.shared.interstitialAdManager.loadInterstitialAd()
                AdManager.shared.rewardedAdManager.loadRewardedAd()
                self.logger.info("広告プリロード要求完了")
            }
        }
        
        // InAppPurchaseManagerとAdManagerの初期化
        _ = InAppPurchaseManager.shared
        _ = AdManager.shared
        
        // 通知の設定
        setupNotificationCategories()
        
        logger.info("AppDelegate: application(_:didFinishLaunchingWithOptions:) 完了")
        return true
    }
    
    // アプリケーションのポリシー同意状態を設定
    private func setConsentPolicy() {
        logger.info("ポリシー同意状態を設定中")
        
        // 地域設定を試みる
        do {
            // EEAユーザー向けの設定 (nilを使用してunspecifiedを表現)
            MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil
            logger.info("年齢による同意設定を完了")
        } catch {
            logger.error("ポリシー同意設定エラー: \(error.localizedDescription)")
        }
    }
    
    // デバイス情報のログ出力
    private func logDeviceInfo() {
        let device = UIDevice.current
        logger.info("デバイス情報:")
        logger.info("- モデル: \(device.model)")
        logger.info("- システムバージョン: \(device.systemVersion)")
        logger.info("- デバイス名: \(device.name)")
        logger.info("- デバイスID: \(device.identifierForVendor?.uuidString ?? "不明")")
        logger.info("- ユーザーインターフェース: \(device.userInterfaceIdiom.rawValue)")
        
        // ネットワーク情報
        if let reachability = try? getNetworkStatus() {
            logger.info("- ネットワーク状態: \(reachability)")
        }
    }
    
    // ネットワーク状態を取得する簡易メソッド
    private func getNetworkStatus() throws -> String {
        let monitor = NWPathMonitor()
        let path = monitor.currentPath
        monitor.cancel()
        return path.status == .satisfied ? "接続中" : "未接続"
    }
    
    // 広告リクエストを更新する - アプリ起動時に広告を事前ロード
    private func refreshAdRequest() {
        // 広告マネージャーを再初期化
        DispatchQueue.main.async {
            // 広告をリロード
            self.logger.info("広告リクエスト更新開始")
            AdManager.shared.interstitialAdManager.loadInterstitialAd()
            AdManager.shared.rewardedAdManager.loadRewardedAd()
            self.logger.info("広告リクエスト更新完了")
        }
    }
    
    // アプリがアクティブになったとき
    func applicationDidBecomeActive(_ application: UIApplication) {
        logger.info("AppDelegate: applicationDidBecomeActive")
        // 直接広告をロードする
        refreshAdRequest()
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