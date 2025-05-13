import SwiftUI
import CoreData
import GoogleMobileAds
import UserNotifications
import StoreKit

// 注: Swiftでは他のファイルを直接インポートすることはできませんが、プロジェクトのレベルでファイルが参照されているため、コンパイル時に問題はありません

struct EnhancedContentView: View {
    @EnvironmentObject var dataStore: CoreDataStore
    
    // AdManagerのインスタンスを使用
    @ObservedObject private var adManager = AdManager.shared
    
    // デバッグビルドかどうかを示す定数
    #if DEBUG
    private let isDebug = true
    #else
    private let isDebug = false
    #endif
    
    @State private var selectedTab: Tab = .home
    @State private var selectedDate = Date()
    @State private var showingHealthRecord = false
    @State private var healthRecordAnimalId: UUID? = nil
    @State private var debugAnimalCount: Int = 0 // デバッグ用
    
    // 通知表示シート
    @State private var showingNotificationSheet = false
    @State private var showingNotificationSettings = false
    
    // フォントサイズスケール環境変数
    @Environment(\.sizeCategory) var sizeCategory
    
    // カラースキーム環境変数（ダークモードの手動変更に対応）
    @Environment(\.colorScheme) var colorScheme
    
    // AppStorageから設定を取得
    @AppStorage("animalIcon") private var animalIcon = "pawprint"
    
    enum Tab {
        case home, calendar, pets, settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EnhancedHomeView(selectedDate: $selectedDate)
                .environmentObject(dataStore)
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }
                .tag(Tab.home)
            
            CalendarTabView(selectedDate: $selectedDate)
                .environmentObject(dataStore)
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
                .tag(Tab.calendar)
            
            EnhancedAnimalListView(selectedDate: $selectedDate)
                .environmentObject(dataStore)
                .tabItem {
                    Label("ペット", systemImage: animalIcon)
                }
                .tag(Tab.pets)
            
            SettingsView()
            .environmentObject(dataStore)
            .tabItem {
                Label("設定", systemImage: "gear")
            }
            .tag(Tab.settings)
        }
        .accentColor(getThemeColors().2)
        // 広告の表示
        .overlay(
            AdContainerView()
                .allowsHitTesting(false)   // タップを下層に通す
        )
        // ナビゲーションバーに通知ボタンを追加
        .navigationBarItems(trailing: 
            Button(action: {
                showingNotificationSheet = true
            }) {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .padding(8)
                    .background(Circle().fill(Color.adaptiveSecondary))
                    .foregroundColor(Color.adaptiveText)
            }
        )
        .onAppear {
            // UIのカスタマイズ
            setupAppearance()
            
            // 通知を監視
            setupNotificationObserver()
            
            // デバッグ用に動物数を記録
            debugAnimalCount = dataStore.animals.count
            print("初期化時の動物数: \(debugAnimalCount)")
            
            // 全動物のIDをデバッグ出力
            for animal in dataStore.animals {
                print("動物: \(animal.name), ID: \(animal.id)")
            }
            
            // アプリ起動時の処理
            adManager.appDidLaunch()
        }
        .sheet(isPresented: $showingHealthRecord, onDismiss: {
            // モーダルが閉じられた後にクリーンアップ
            self.healthRecordAnimalId = nil
        }) {
            if let animalId = healthRecordAnimalId, let animal = dataStore.animals.first(where: { $0.id == animalId }) {
                // 動物が見つかった場合は健康記録画面を表示
                NavigationView {
                    HealthRecordView(animalId: animalId, isEmbedded: true)
                        .environmentObject(dataStore)
                        .navigationBarItems(leading: Button("閉じる") {
                            showingHealthRecord = false
                        })
                }
            } else {
                // 動物が見つからない場合はエラーメッセージを表示
                VStack(spacing: 20) {
                    Text("エラー: ペット情報が見つかりません")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                    
                    Text("存在しないか削除されたペットの健康記録を開こうとしました")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("閉じる") {
                        showingHealthRecord = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        // 通知一覧シートを表示
        .sheet(isPresented: $showingNotificationSheet) {
            NavigationView {
                VStack {
                    List {
                        Section(header: Text("未読の通知")) {
                            ForEach(0..<3) { i in
                                HStack(spacing: 12) {
                                    Image(systemName: i == 0 ? "drop.fill" : (i == 1 ? "heart.text.square.fill" : "syringe.fill"))
                                        .font(.title3)
                                        .foregroundColor(i == 0 ? .red : (i == 1 ? .blue : .green))
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(i == 0 ? "ポチの生理予測" : (i == 1 ? "ミルクの健康診断" : "ポチのワクチン接種"))
                                            .font(.headline)
                                        
                                        Text(i == 0 ? "明日から生理が始まる可能性があります。" : 
                                             (i == 1 ? "明日は健康診断の予定日です。" : "来週、狂犬病ワクチンの接種ため病院へ行きましょう。"))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                        
                                        Text("最終更新: 2025/5/10")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                                .swipeActions {
                                    Button(role: .destructive) {
                                        // 通知を削除
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        
                        Section(header: Text("予定更新")) {
                            Button(action: {
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                                    // 通知許可リクエスト
                                }
                            }) {
                                HStack {
                                    Text("通知を許可する")
                                    Spacer()
                                    Image(systemName: "bell.badge")
                                }
                            }
                            
                            Toggle("生理周期通知", isOn: .constant(true))
                            Toggle("健康診断リマインダー", isOn: .constant(true))
                            Toggle("ワクチン接種通知", isOn: .constant(true))
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                .navigationTitle("通知")
                .navigationBarItems(leading: Button("閉じる") {
                    showingNotificationSheet = false
                })
            }
        }
        .onChange(of: selectedTab) { newTab in
            // AdManagerを使用してタブ変更時の広告表示を管理
            adManager.onTabChange()
            // タブ変更時のデバッグ出力
            print("タブが変更されました: \(newTab)")
        }
    }
    
    private func setupAppearance() {
        // テーマに基づいた色を取得
        let (backgroundColor, textColor, accentColor) = getThemeColors()
        
        // UITabBarの見た目をカスタマイズ
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = UIColor(backgroundColor)
        appearance.shadowColor = UIColor(Color.black.opacity(0.1))
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // UINavigationBarの見た目をカスタマイズ
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(backgroundColor)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(textColor)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(textColor)]
        navAppearance.shadowColor = UIColor(Color.black.opacity(0.1))
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        }
        
        // タブバーの選択色を設定
        UITabBar.appearance().tintColor = UIColor(accentColor)
    }
    
    private func getThemeColors() -> (Color, Color, Color) {
        // デフォルトの色を返す
        let isDarkMode = colorScheme == .dark
        
        // ダークモード対応
        if isDarkMode {
            return (Color(.systemBackground), Color.white, Color.blue)
        } else {
            return (Color.white, Color.black, Color.blue)
        }
    }
    
    private func setupNotificationObserver() {
        // タブ切り替え通知の監視
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SwitchToTab"), object: nil, queue: .main) { notification in
            if let tab = notification.object as? Tab {
                // タブ変更を即時反映し、UI更新を明示的に強制する
                DispatchQueue.main.async {
                    withAnimation {
                        self.selectedTab = tab
                    }
                    // 変更を確実に反映するためにUIの更新を強制
                    print("タブ切り替え: \(tab)")
                }
            }
        }
        
        // 直接健康記録画面を開く通知の監視
        NotificationCenter.default.addObserver(forName: NSNotification.Name("DirectOpenHealthRecord"), object: nil, queue: .main) { notification in
            if let animalId = notification.object as? UUID {
                // 現在の動物数を確認
                let currentAnimalCount = self.dataStore.animals.count
                print("健康記録表示前の動物数: \(currentAnimalCount)")
                print("全動物ID: \(self.dataStore.animals.map { $0.id })")
                
                // 健康記録画面をモーダルで表示する前に動物IDを設定
                self.healthRecordAnimalId = animalId
                print("健康記録を開く動物ID: \(animalId)")
                
                // 動物情報があるか確認
                if let animal = self.dataStore.animals.first(where: { $0.id == animalId }) {
                    print("動物情報が見つかりました: \(animal.name)")
                    // CoreDataから必要なデータを再読み込み
                    self.dataStore.loadData()
                    
                    // 動物が存在する場合はモーダルを表示
                    DispatchQueue.main.async {
                        self.showingHealthRecord = true
                    }
                } else {
                    print("警告: 動物ID \(animalId) を持つ動物が見つかりません")
                    // 通知があっても動物が見つからない場合は、データの再読み込みを試行
                    self.dataStore.loadData()
                    
                    // 再読み込み後に確認
                    if let animalAfterReload = self.dataStore.animals.first(where: { $0.id == animalId }) {
                        print("再読み込み後に動物が見つかりました: \(animalAfterReload.name)")
                        // モーダルを表示
                        DispatchQueue.main.async {
                            self.showingHealthRecord = true
                        }
                    } else {
                        print("再読み込み後も動物が見つかりませんでした")
                    }
                }
            }
        }
    }
}

struct CalendarTabView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject var dataStore: CoreDataStore
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    EnhancedCalendarView(selectedDate: $selectedDate)
                        .environmentObject(dataStore)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("カレンダー")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var dataStore: CoreDataStore
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("animalIcon") private var animalIcon = "pawprint"
    @State private var isProductionEnvironment = false
    @ObservedObject private var purchaseManager = InAppPurchaseManager.shared
    @ObservedObject private var adManager = AdManager.shared
    
    // デバッグビルドかどうかを示す定数
    #if DEBUG
    private let isDebug = true
    #else
    private let isDebug = false
    #endif
    @State private var showingPremiumView = false
    @State private var showingDataManagementView = false
    @State private var showingPrivacyPolicy = false
    @State private var showingSupportView = false
    @State private var showingCSVExportView = false
    @State private var showingNotificationSettings = false
    
    // Use standard property wrapper for compatibility with older iOS versions
    @State private var reminderTime = Date(timeIntervalSince1970: 32400) // 9:00 AM
    
    // 利用可能な動物アイコンの配列
    private let availableAnimalIcons = [
        ("pawprint", "肉球"),
        ("hare", "うさぎ"),
        ("tortoise", "かめ"),
        ("bird", "鳥"),
        ("cat", "猫"),
        ("dog", "犬"),
        ("ladybug", "虫"),
        ("ant", "アリ"),
        ("fish", "魚")
    ]
    
    // Initialize from UserDefaults manually
    init() {
        if let storedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
            _reminderTime = State(initialValue: storedTime)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("一般設定")) {
                    Toggle("通知", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                // 通知が有効化された場合は権限リクエスト
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                                    if let error = error {
                                        print("通知権限リクエストエラー: \(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                    
                    if notificationsEnabled {
                        DatePicker("リマインダー時間", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "reminderTime")
                        }
                        
                        Button(action: {
                            showingNotificationSettings = true
                        }) {
                            HStack {
                                Text("通知設定")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // 動物アイコン選択セクション
                Section(header: Text("ペットアイコン")) {
                    Picker("タブアイコン", selection: $animalIcon) {
                        ForEach(availableAnimalIcons, id: \.0) { iconName, displayName in
                            Label(displayName, systemImage: iconName)
                                .tag(iconName)
                        }
                    }
                    .pickerStyle(NavigationLinkPickerStyle())
                    
                    // プレビュー
                    HStack {
                        Text("現在のアイコン")
                        Spacer()
                        Image(systemName: animalIcon)
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("データ管理")) {
                    Button(action: {
                        showingDataManagementView = true
                    }) {
                        Label("データのバックアップと復元", systemImage: "externaldrive")
                    }
                    
                    Button(action: {
                        showingCSVExportView = true
                    }) {
                        Label("データのCSVエクスポート", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section(header: Text("アプリについて")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showingSupportView = true
                    }) {
                        Label("サポート", systemImage: "questionmark.circle")
                    }
                    
                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
                        Label("プライバシーポリシー", systemImage: "hand.raised")
                    }
                }
                
                Section(header: Text("広告")) {
                    // 現在のプレミアムステータスを表示
                    HStack {
                        Text("ステータス")
                        Spacer()
                        if purchaseManager.hasRemoveAdsPurchased() {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text("プレミアム")
                                    .foregroundColor(.yellow)
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                        } else if purchaseManager.debugPremiumEnabled {
                            HStack(spacing: 4) {
                                Image(systemName: "ladybug.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("デバッグモード")
                                    .foregroundColor(.green)
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                        } else {
                            Text("無料版")
                                .foregroundColor(.gray)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    
                    if purchaseManager.hasRemoveAdsPurchased() || purchaseManager.debugPremiumEnabled {
                        Text("広告は表示されません")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        // プレミアム機能の表示フラグがオンの場合のみ購入ボタンを表示
                        if InAppPurchaseManager.showPremiumFeatures {
                            Button(action: {
                                showingPremiumView = true
                            }) {
                                HStack {
                                    Text("広告を非表示にする")
                                    Spacer()
                                    Text("プレミアムにアップグレード")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.yellow)
                                        .foregroundColor(.black)
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            Text("広告はアプリの実行をサポートしています")
                                .font(.caption)
                        }
                        
                        Text("このアプリは広告によって支援されています")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Link(destination: URL(string: "https://policies.google.com/privacy")!) {
                            Label("AdMobプライバシーポリシー", systemImage: "link")
                                .font(.caption)
                        }
                    }
                }
                
                // デバッグセクション
                #if DEBUG
                // プレミアム機能の表示フラグがtrueの場合のみ表示
                if InAppPurchaseManager.showPremiumFeatures {
                    Section(header: Text("デバッグ設定")) {
                        Toggle("プレミアムモード", isOn: $purchaseManager.debugPremiumEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                            .onChange(of: purchaseManager.debugPremiumEnabled) { newValue in
                                print("デバッグプレミアムモード: \(newValue)")
                                // 通知を手動で送信
                                NotificationCenter.default.post(name: NSNotification.Name("PremiumStatusChanged"), object: nil)
                                // UIを即時更新
                                self.updateUI()
                            }
                        
                        // 環境切り替えトグル
                        Toggle("本番環境", isOn: $isProductionEnvironment)
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                            .onChange(of: isProductionEnvironment) { newValue in
                                print("本番環境モード: \(newValue)")
                                
                                // SubscriptionManagerの環境を切り替え
                                let environment: SubscriptionEnvironment = newValue ? .production : .debug
                                SubscriptionManager.shared.switchEnvironment(to: environment)
                                
                                // UIを即時更新
                                self.updateUI()
                            }
                        
                        if isProductionEnvironment {
                            Text("本番環境のプロダクトIDが使用されます")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("開発環境のプロダクトIDが使用されます")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        // 本番環境のプロダクトID表示
                        VStack(alignment: .leading, spacing: 4) {
                            Text("本番環境のプロダクトID:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("月額: SerenoSystem_animalgestione.premium_monthly")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("年額: SerenoSystem_animalgestione.premium_yearly_two")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("永久: SerenoSystem_animalgestione.premium_lifetime")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        if purchaseManager.debugPremiumEnabled {
                            Text("デバッグ用のプレミアムモードが有効です")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        // 購入のリセットボタンを追加
                        Button(action: {
                            // iOS 15以上のみでサポート
                            if #available(iOS 15.0, *) {
                                Task {
                                    await resetPurchases()
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                Text("サブスクリプション購入をリセット")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .onAppear {
                        // 画面が表示されたときに通知を購読
                        setupPremiumNotifications()
                    }
                    .onDisappear {
                        // 画面が非表示されたときに購読を解除
                        NotificationCenter.default.removeObserver(self)
                    }
                }
                #endif

            }
            .navigationTitle("設定")
            .listStyle(InsetGroupedListStyle())
        }
        .sheet(isPresented: $showingPremiumView) {
            // プレミアム機能の表示フラグがオンの場合のみ表示
            if InAppPurchaseManager.showPremiumFeatures {
                // 新しいStoreKit 2に基づく購入画面を表示
                PremiumSubscriptionView()
            } else {
                // プレミアム機能が無効な場合は単純なメッセージを表示
                VStack(spacing: 20) {
                    Text("この機能は現在利用できません")
                        .font(.headline)
                    
                    Button("閉じる") {
                        showingPremiumView = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NavigationView {
                List {
                    Section(header: Text("通知設定")) {
                        Toggle("通知を許可する", isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { newValue in
                                if newValue {
                                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                                        if let error = error {
                                            print("通知権限リクエストエラー: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }
                        
                        if notificationsEnabled {
                            DatePicker("リマインダー時間", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "reminderTime")
                            }
                        }
                    }
                    
                    if notificationsEnabled {
                        Section(header: Text("通知タイプ")) {
                            Toggle("生理周期通知", isOn: .constant(true))
                            Toggle("健康診断リマインダー", isOn: .constant(true))
                            Toggle("ワクチン接種通知", isOn: .constant(true))
                            Toggle("予定リマインダー", isOn: .constant(true))
                        }
                        
                        Section(header: Text("リマインダータイミング")) {
                            Picker("予定日通知", selection: .constant(1)) {
                                Text("当日").tag(0)
                                Text("一日前").tag(1)
                                Text("二日前").tag(2)
                                Text("三日前").tag(3)
                            }
                        }
                    }
                    
                    Section(header: Text("通知履歴")) {
                        Button(action: {
                            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                        }) {
                            Text("すべての通知をクリア")
                                .foregroundColor(.red)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("通知設定")
                .navigationBarItems(leading: Button("閉じる") {
                    showingNotificationSettings = false
                })
            }
        }
        // データ管理ビューを表示
        .sheet(isPresented: $showingDataManagementView) {
            DataManagementView()
                .environmentObject(dataStore)
        }
        // CSVエクスポートビューを表示
        .sheet(isPresented: $showingCSVExportView) {
            CSVExportView()
        }
        // プライバシーポリシービューを表示
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationView {
                PrivacyPolicyView()
            }
        }
        // サポートビューを表示
        .sheet(isPresented: $showingSupportView) {
            NavigationView {
                SupportView()
            }
        }
        .onAppear {
            // 通知の権限状態を確認
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                print("通知設定状態: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    // プレミアムステータス変更の通知設定
    private func setupPremiumNotifications() {
        // プレミアムステータス変更通知を購読
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PremiumStatusChanged"),
            object: nil,
            queue: .main
        ) { _ in
            // 即座に画面をリロードする
            self.updateUI()
        }
        
        // プレミアム購入完了通知を購読
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PremiumPurchaseCompleted"),
            object: nil,
            queue: .main
        ) { _ in
            // プレミアムビューを閉じて画面を更新
            self.showingPremiumView = false
            self.updateUI()
        }
    }
    
    // UI更新用メソッド
    private func updateUI() {
        // 強制的にビューを再描画させるためのState変更を追加
        @State var refreshTrigger = UUID()
        refreshTrigger = UUID()
        // ビューを再描画する別の方法でUI更新を行う
        DispatchQueue.main.async {
            // ViewをRefreshする
            self.purchaseManager.objectWillChange.send()
            // 広告状態も更新
            AdManager.shared.objectWillChange.send()
        }
    }
    
    // サブスクリプション購入をリセットする関数
    @available(iOS 15.0, *)
    private func resetPurchases() async {
        // InAppPurchaseManagerのクリアメソッドを利用
        purchaseManager.clearPurchases()
        
        // UserDefaultsに保存された可能性のある購入情報もクリア
        UserDefaults.standard.removeObject(forKey: "purchasedProductIDs")
        UserDefaults.standard.removeObject(forKey: "purchaseReceipt")
        UserDefaults.standard.removeObject(forKey: "subscriptionExpiryDate")
        UserDefaults.standard.synchronize()
        
        // 詳細なログを出力
        print("サブスクリプション情報をリセットしました")
        
        // UIを即時更新
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("PremiumStatusChanged"), object: nil)
            AdManager.shared.objectWillChange.send()
            self.purchaseManager.objectWillChange.send()
            self.updateUI()
        }
    }
}
