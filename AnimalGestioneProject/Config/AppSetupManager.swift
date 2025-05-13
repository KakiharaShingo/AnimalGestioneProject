import Foundation
import SwiftUI

class AppSetupManager: ObservableObject {
    static let shared = AppSetupManager()
    
    private let defaults = UserDefaults.standard
    
    @Published var shouldShowPrivacyPolicy = false
    
    // バージョン管理用のキー
    private let currentVersionKey = "currentAppVersion"
    private let privacyPolicyAcceptedKey = "privacyPolicyAccepted"
    private let privacyPolicyVersionKey = "privacyPolicyVersion"
    
    // プライバシーポリシーのURLはURLProviderクラスで管理
    
    private init() {
        checkAppVersion()
    }
    
    // アプリバージョンをチェックし、初回起動やアップデート後の処理を行う
    func checkAppVersion() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let storedVersion = defaults.string(forKey: currentVersionKey)
        
        // プライバシーポリシーの最新バージョン
        let currentPrivacyPolicyVersion = "1.0" // プライバシーポリシーを変更した場合はこの値を更新
        let storedPrivacyPolicyVersion = defaults.string(forKey: privacyPolicyVersionKey)
        
        // 初回起動の場合
        if storedVersion == nil {
            defaults.set(currentVersion, forKey: currentVersionKey)
            defaults.set(false, forKey: privacyPolicyAcceptedKey)
            defaults.set(currentPrivacyPolicyVersion, forKey: privacyPolicyVersionKey)
            shouldShowPrivacyPolicy = true
        }
        // アップデートの場合
        else if storedVersion != currentVersion {
            defaults.set(currentVersion, forKey: currentVersionKey)
            // アップデート時の処理をここに記述
        }
        
        // プライバシーポリシーが更新された場合
        if storedPrivacyPolicyVersion != currentPrivacyPolicyVersion {
            defaults.set(currentPrivacyPolicyVersion, forKey: privacyPolicyVersionKey)
            defaults.set(false, forKey: privacyPolicyAcceptedKey)
            shouldShowPrivacyPolicy = true
        }
        
        // プライバシーポリシーが未承認の場合
        if !defaults.bool(forKey: privacyPolicyAcceptedKey) {
            shouldShowPrivacyPolicy = true
        }
    }
    
    // プライバシーポリシーの承認を記録
    func acceptPrivacyPolicy() {
        defaults.set(true, forKey: privacyPolicyAcceptedKey)
        shouldShowPrivacyPolicy = false
    }
    
    // アプリのデフォルト設定をセットアップ
    func setupAppDefaults() {
        // 通知設定（デフォルトで有効）
        if defaults.object(forKey: "notificationsEnabled") == nil {
            defaults.set(true, forKey: "notificationsEnabled")
        }
        
        // リマインダー時間（デフォルトは9:00 AM）
        if defaults.object(forKey: "reminderTime") == nil {
            // 9:00 AMを表す日付を作成
            let calendar = Calendar.current
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            if let date = calendar.date(from: components) {
                defaults.set(date, forKey: "reminderTime")
            }
        }
        
        // カラーテーマ（デフォルトはスタンダード）
        if defaults.string(forKey: "colorTheme") == nil {
            defaults.set("standard", forKey: "colorTheme")
        }
        
        // 動物アイコン（デフォルトは肉球）
        if defaults.string(forKey: "animalIcon") == nil {
            defaults.set("pawprint", forKey: "animalIcon")
        }
    }
}
