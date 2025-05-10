import SwiftUI
import CoreData
import GoogleMobileAds

@main
struct AnimalGestioneProjectApp: App {
    // CoreDataの永続コントローラを設定
    let persistenceController = PersistenceController.shared
    
    // CoreDataStoreを環境オブジェクトとして提供
    @StateObject private var dataStore = CoreDataStore()
    
    // AppDelegateをアプリに接続
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var showSplash = true // スプラッシュ画面表示管理
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // メインのContentView（EnhancedContentViewを使用）
                EnhancedContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(dataStore)
                    // ダークモードをサポートするため、明示的な色指定を削除
                
                // スプラッシュ画面（条件付きで表示）
                if showSplash {
                    SplashScreen(showSplash: $showSplash)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // 初回起動時の設定
                setupAppDefault()
            }
        }
    }
    
    // アプリのデフォルト設定をセットアップ
    private func setupAppDefault() {
        // UserDefaultsで初期設定が行われていなければ初期値を設定
        let defaults = UserDefaults.standard
        
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
