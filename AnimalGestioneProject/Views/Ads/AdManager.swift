import SwiftUI
import StoreKit
import Network
import UIKit
import os.log

/// アプリ全体の広告表示を管理するシングルトンクラス
@MainActor
class AdManager: ObservableObject {
    static let shared = AdManager()
    
    // ロガーの設定
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.animalgestione", category: "AdManager")
    
    // 各種広告マネージャーのインスタンス
    @Published var interstitialAdManager: InterstitialAdManager
    @Published var rewardedAdManager: RewardedAdManager
    
    // アプリ内課金マネージャー
    @Published var purchaseManager = InAppPurchaseManager.shared
    
    // 広告表示のカウンター
    @Published var tabChangeCounter: Int = 0
    
    // ネットワーク監視用
    private var networkMonitor: NWPathMonitor?
    private var isNetworkAvailable = true
    private var retryCount = 0
    private let maxRetryCount = 3
    private let retryDelay: TimeInterval = 2.0
    private var lastAdLoadTime: Date?
    private let minimumAdLoadInterval: TimeInterval = 5.0
    private var networkStatusHistory: [(Date, NWPath.Status)] = []
    private let maxHistoryCount = 10
    
    // ネットワーク監視用の追加プロパティ
    private var connectionRetryCount = 0
    private let maxConnectionRetryCount = 10
    private let connectionRetryDelay: TimeInterval = 5.0
    private var lastConnectionError: Error?
    private var isRetryingConnection = false
    private var quicProtocolEnabled = false
    private var consecutiveConnectionFailures = 0
    private let maxConsecutiveFailures = 5
    private var lastNetworkType: String = ""
    private var networkQualityCheckTimer: Timer?
    private var lastSuccessfulConnection: Date?
    private var connectionFailureHistory: [(Date, Error)] = []
    private let maxFailureHistoryCount = 10
    private var isQUICDisabled = false
    private var lastQUICDisableTime: Date?
    private let quicDisableDuration: TimeInterval = 600 // 10分間に延長
    private var networkStabilityTimer: Timer?
    private var stableConnectionDuration: TimeInterval = 0
    private let requiredStableDuration: TimeInterval = 30
    private var lastNetworkResetTime: Date?
    private let networkResetInterval: TimeInterval = 900
    private var isWiredConnection = false
    private var lastConnectionType: NWInterface.InterfaceType?
    private var connectionTypeChangeCount = 0
    private let maxConnectionTypeChanges = 3
    private var lastConnectionTypeChangeTime: Date?
    private let connectionTypeChangeCooldown: TimeInterval = 60 // 1分間
    
    // デバイス情報
    private var deviceInfo: String {
        let device = UIDevice.current
        let systemVersion: String = device.systemVersion
        let model: String = device.model
        let identifier: String = device.identifierForVendor?.uuidString ?? "不明"
        let batteryLevel: Float = device.batteryLevel
        let batteryState: UIDevice.BatteryState = device.batteryState
        
        logger.debug("デバイス情報: モデル=\(model), バージョン=\(systemVersion), ID=\(identifier), バッテリー=\(batteryLevel), 状態=\(batteryState.rawValue)")
        
        return """
        デバイス: \(model)
        システムバージョン: \(systemVersion)
        モデル識別子: \(identifier)
        バッテリーレベル: \(batteryLevel)
        バッテリー状態: \(batteryState.rawValue)
        ネットワークタイプ: \(currentNetworkType)
        低電力モード: \(ProcessInfo.processInfo.isLowPowerModeEnabled)
        """
    }
    
    // 現在のネットワークタイプ
    private var currentNetworkType: String {
        guard let path = networkMonitor?.currentPath else { return "不明" }
        
        let type: String
        if path.usesInterfaceType(.wifi) {
            type = "WiFi"
        } else if path.usesInterfaceType(.cellular) {
            type = "セルラー"
        } else if path.usesInterfaceType(.wiredEthernet) {
            type = "有線"
        } else {
            type = "その他"
        }
        
        // ネットワークタイプが変更された場合のログ
        if type != self.lastNetworkType {
            logger.info("ネットワークタイプ変更: \(self.lastNetworkType) -> \(type)")
            self.lastNetworkType = type
        }
        
        return type
    }
    
    // 初期化
    private init() {
        logger.info("AdManager初期化開始")
        
        // 広告マネージャーの初期化
        self.interstitialAdManager = InterstitialAdManager(adUnitID: AdConfig.interstitialAdUnitId)
        self.rewardedAdManager = RewardedAdManager(adUnitID: AdConfig.rewardedAdUnitId)
        
        // ネットワーク監視の設定
        setupNetworkMonitoring()
        
        // ネットワーク安定性チェックの設定
        setupNetworkStabilityCheck()
        
        // Note: AdMobの初期化は別の場所で行われるように変更
        logger.info("AdMob SDKの初期化をスキップ")
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            // 前回のQUIC無効化状態を確認
            if let lastDisableTime = UserDefaults.standard.object(forKey: "\(bundleIdentifier).quic_last_disable_time") as? Date,
               Date().timeIntervalSince(lastDisableTime) < quicDisableDuration {
                isQUICDisabled = true
                logger.info("QUICプロトコルは一時的に無効化されています")
            } else {
                // デフォルトでQUICを無効化
                UserDefaults.standard.set(false, forKey: "\(bundleIdentifier).quic_enabled")
                quicProtocolEnabled = false
                isQUICDisabled = true
                logger.info("QUICプロトコルを無効化（デフォルト設定）")
            }
        }
        
        // デバイス設定
        configureTestDevices()
        
        // ネットワーク品質チェックタイマーの設定
        setupNetworkQualityCheck()
        
        logger.info("AdManager初期化完了")
    }
    
    // ネットワーク品質チェックの設定
    private func setupNetworkQualityCheck() {
        networkQualityCheckTimer?.invalidate()
        networkQualityCheckTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.checkNetworkQuality()
        }
    }
    
    // ネットワーク品質のチェック
    private func checkNetworkQuality() {
        guard let path = networkMonitor?.currentPath else { return }
        
        // 接続失敗履歴の分析
        let recentFailures = connectionFailureHistory.filter { 
            Date().timeIntervalSince($0.0) < 300 // 直近5分間の失敗
        }
        
        let quality = """
        ネットワーク品質チェック:
        状態: \(path.status)
        インターフェース数: \(path.availableInterfaces.count)
        インターフェース詳細: \(path.availableInterfaces.map { "- \($0.name): \($0.type)" }.joined(separator: "\n"))
        高額接続: \(path.isExpensive)
        制限付き接続: \(path.isConstrained)
        接続失敗回数: \(consecutiveConnectionFailures)
        直近5分間の失敗回数: \(recentFailures.count)
        最終エラー: \(lastConnectionError?.localizedDescription ?? "なし")
        最終成功接続: \(lastSuccessfulConnection?.description ?? "なし")
        QUIC状態: \(isQUICDisabled ? "無効" : "有効")
        """
        
        logger.info("\(quality, privacy: .public)")
        
        // 接続の品質が悪い場合の対策
        if path.status == .unsatisfied || consecutiveConnectionFailures >= maxConsecutiveFailures {
            handlePoorNetworkQuality()
        }
        
        // 直近の失敗が多すぎる場合の対策
        if recentFailures.count >= 3 {
            logger.warning("直近5分間で3回以上の接続失敗を検出")
            handleConnectionFailures()
        }
    }
    
    // ネットワーク品質が悪い場合の処理
    private func handlePoorNetworkQuality() {
        logger.warning("ネットワーク品質が低下 - 対策を実行")
        
        // QUICプロトコルを無効化
        disableQUICProtocol()
        
        // 接続状態をリセット
        resetConnectionState()
        
        // ネットワークモニターを再設定
        Task { @MainActor in
            self.networkMonitor?.cancel()
            self.networkMonitor = nil
            self.setupNetworkMonitoring()
        }
    }
    
    // ネットワーク安定性チェックの設定
    private func setupNetworkStabilityCheck() {
        networkStabilityTimer?.invalidate()
        networkStabilityTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.checkNetworkStability()
        }
    }
    
    // ネットワーク安定性のチェック
    private func checkNetworkStability() {
        guard let path = networkMonitor?.currentPath else { return }
        
        if path.status == .satisfied {
            stableConnectionDuration += 1.0
            
            // 安定した接続が一定時間続いた場合
            if stableConnectionDuration >= requiredStableDuration {
                // ネットワーク設定の定期的なリセット
                if let lastReset = lastNetworkResetTime,
                   Date().timeIntervalSince(lastReset) >= networkResetInterval {
                    resetNetworkSettings()
                }
            }
        } else {
            stableConnectionDuration = 0
        }
    }
    
    // ネットワーク設定のリセット
    private func resetNetworkSettings() {
        logger.info("ネットワーク設定の定期的なリセットを実行")
        
        lastNetworkResetTime = Date()
        
        // ネットワークモニターの再設定
        Task { @MainActor in
            self.networkMonitor?.cancel()
            self.networkMonitor = nil
            
            // QUICプロトコルの状態を確認
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                if !isQUICDisabled {
                    UserDefaults.standard.set(false, forKey: "\(bundleIdentifier).quic_enabled")
                    logger.info("QUICプロトコルを無効化（定期的なリセット）")
                }
            }
            
            self.setupNetworkMonitoring()
        }
    }
    
    // ネットワーク監視の設定
    private func setupNetworkMonitoring() {
        logger.info("ネットワーク監視の設定開始")
        
        // 既存のモニターをクリーンアップ
        networkMonitor?.cancel()
        
        // 新しいモニターを作成（WiFi、セルラー、有線を個別に監視）
        let wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
        let cellularMonitor = NWPathMonitor(requiredInterfaceType: .cellular)
        let wiredMonitor = NWPathMonitor(requiredInterfaceType: .wiredEthernet)
        
        let updateHandler: (NWPath) -> Void = { [weak self] path in
            guard let self = self else { return }
            
            Task { @MainActor in
                let previousStatus = self.isNetworkAvailable
                self.isNetworkAvailable = path.status == .satisfied
                
                // 接続タイプの変更を検出
                if let currentType = path.availableInterfaces.first?.type {
                    if self.lastConnectionType != currentType {
                        self.handleConnectionTypeChange(from: self.lastConnectionType, to: currentType)
                        self.lastConnectionType = currentType
                    }
                }
                
                // 有線接続の状態を更新
                self.isWiredConnection = path.usesInterfaceType(.wiredEthernet)
                
                // ネットワーク状態の履歴を記録
                self.recordNetworkStatus(path.status)
                
                // ネットワーク状態の変更をログ出力
                if previousStatus != self.isNetworkAvailable {
                    self.logNetworkStatusChange(path: path)
                    
                    if self.isNetworkAvailable {
                        self.handleConnectionRestored(path: path)
                    } else {
                        self.handleConnectionLost(path: path)
                    }
                }
            }
        }
        
        wifiMonitor.pathUpdateHandler = updateHandler
        cellularMonitor.pathUpdateHandler = updateHandler
        wiredMonitor.pathUpdateHandler = updateHandler
        
        // 監視開始
        let queue = DispatchQueue(label: "com.animalgestione.networkmonitor", qos: .utility)
        wifiMonitor.start(queue: queue)
        cellularMonitor.start(queue: queue)
        wiredMonitor.start(queue: queue)
        
        // モニターを保持（プライマリとして有線接続を優先）
        self.networkMonitor = wiredMonitor
        
        logger.info("ネットワーク監視開始（WiFi + セルラー + 有線）")
    }
    
    // 接続タイプの文字列表現を取得
    private func getInterfaceTypeDescription(_ type: NWInterface.InterfaceType?) -> String {
        guard let type = type else { return "不明" }
        
        switch type {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "セルラー"
        case .wiredEthernet:
            return "有線"
        case .loopback:
            return "ループバック"
        case .other:
            return "その他"
        @unknown default:
            return "不明"
        }
    }
    
    // 接続タイプ変更の処理
    private func handleConnectionTypeChange(from oldType: NWInterface.InterfaceType?, to newType: NWInterface.InterfaceType) {
        let now = Date()
        
        // クールダウン期間をチェック
        if let lastChange = lastConnectionTypeChangeTime,
           now.timeIntervalSince(lastChange) < connectionTypeChangeCooldown {
            return
        }
        
        connectionTypeChangeCount += 1
        lastConnectionTypeChangeTime = now
        
        let oldTypeStr = getInterfaceTypeDescription(oldType)
        let newTypeStr = getInterfaceTypeDescription(newType)
        logger.info("接続タイプ変更: \(oldTypeStr) -> \(newTypeStr)")
        
        if connectionTypeChangeCount >= maxConnectionTypeChanges {
            logger.warning("接続タイプの変更が頻繁に発生 - ネットワーク設定をリセット")
            resetNetworkSettings()
            connectionTypeChangeCount = 0
        }
    }
    
    // 接続復旧時の処理
    private func handleConnectionRestored(path: NWPath) {
        logger.info("ネットワーク接続復旧 - 広告再読み込みをスケジュール")
        lastSuccessfulConnection = Date()
        stableConnectionDuration = 0
        
        // 接続が復旧した場合、少し待ってから広告を再読み込み
        Task { @MainActor in
            // 有線接続の場合は即時、その他の場合は遅延を設定
            let delay = isWiredConnection ? 1.0 : connectionRetryDelay
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await self.loadAds()
        }
    }
    
    // 接続喪失時の処理
    private func handleConnectionLost(path: NWPath) {
        logger.warning("ネットワーク接続喪失")
        consecutiveConnectionFailures += 1
        stableConnectionDuration = 0
        
        // 有線接続の場合は即時、その他の場合は通常の処理
        if isWiredConnection {
            logger.info("有線接続の喪失を検出 - 即時再接続を試行")
            Task { @MainActor in
                await self.retryConnection()
            }
        } else {
            handleConnectionLoss()
        }
    }
    
    // 接続状態のリセット
    private func resetConnectionState() {
        connectionRetryCount = 0
        lastConnectionError = nil
        isRetryingConnection = false
        consecutiveConnectionFailures = 0
        logger.info("接続状態をリセット")
    }
    
    // 接続喪失時の処理
    private func handleConnectionLoss() {
        guard !self.isRetryingConnection else { return }
        
        self.isRetryingConnection = true
        self.connectionRetryCount += 1
        
        // 接続失敗を記録
        if let error = lastConnectionError {
            connectionFailureHistory.append((Date(), error))
            if connectionFailureHistory.count > maxFailureHistoryCount {
                connectionFailureHistory.removeFirst()
            }
        }
        
        if self.connectionRetryCount >= self.maxConnectionRetryCount {
            logger.warning("最大接続再試行回数に達しました - QUICプロトコルを無効化")
            self.disableQUICProtocol()
            self.resetConnectionState()
        } else {
            logger.info("接続再試行 (\(self.connectionRetryCount)/\(self.maxConnectionRetryCount))")
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(self.connectionRetryDelay * 1_000_000_000))
                await self.retryConnection()
            }
        }
    }
    
    // QUICプロトコルの無効化
    private func disableQUICProtocol() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.set(false, forKey: "\(bundleIdentifier).quic_enabled")
            quicProtocolEnabled = false
            logger.info("QUICプロトコルを無効化しました")
            
            // ネットワーク設定のリセット
            Task { @MainActor in
                self.networkMonitor?.cancel()
                self.networkMonitor = nil
                self.setupNetworkMonitoring()
            }
        }
    }
    
    // 接続の再試行
    private func retryConnection() async {
        guard self.isRetryingConnection else { return }
        
        logger.info("接続再試行開始")
        
        // 既存の接続をクリーンアップ
        self.networkMonitor?.cancel()
        self.networkMonitor = nil
        
        // 新しい接続の設定
        setupNetworkMonitoring()
        
        // 広告の再読み込み
        await self.loadAds()
        
        self.isRetryingConnection = false
    }
    
    // ネットワーク状態の履歴を記録
    private func recordNetworkStatus(_ status: NWPath.Status) {
        let now = Date()
        networkStatusHistory.append((now, status))
        
        // 履歴の最大数を制限
        if networkStatusHistory.count > maxHistoryCount {
            networkStatusHistory.removeFirst()
        }
        
        // 状態変化のパターンを分析
        if networkStatusHistory.count >= 3 {
            let recentStatuses = networkStatusHistory.suffix(3).map { $0.1 }
            if recentStatuses.allSatisfy({ $0 == .unsatisfied }) {
                logger.warning("ネットワーク接続が3回連続で喪失")
                consecutiveConnectionFailures += 1
                
                if consecutiveConnectionFailures >= maxConsecutiveFailures {
                    handlePoorNetworkQuality()
                }
            }
        }
    }
    
    // ネットワーク状態の変更をログ出力
    private func logNetworkStatusChange(path: NWPath) {
        let status = path.status
        let interfaces = path.availableInterfaces.map { $0.name }.joined(separator: ", ")
        let isExpensive = path.isExpensive
        let isConstrained = path.isConstrained
        
        let logMessage = """
        ネットワーク状態変更:
        デバイス情報: \(deviceInfo)
        状態: \(status)
        利用可能インターフェース: \(interfaces)
        高額接続: \(isExpensive)
        制限付き接続: \(isConstrained)
        詳細:
        - WiFi: \(path.usesInterfaceType(.wifi))
        - セルラー: \(path.usesInterfaceType(.cellular))
        - 有線: \(path.usesInterfaceType(.wiredEthernet))
        - その他: \(path.usesInterfaceType(.other))
        - 接続状態: \(path.status)
        - インターフェース数: \(path.availableInterfaces.count)
        - インターフェース詳細: \(interfaces)
        - 連続失敗回数: \(consecutiveConnectionFailures)
        - 最終エラー: \(lastConnectionError?.localizedDescription ?? "なし")
        """
        
        logger.info("\(logMessage, privacy: .public)")
        
        // ネットワーク接続が失われた場合の追加情報
        if status == .unsatisfied {
            let additionalInfo = """
            追加情報:
            バッテリーレベル: \(UIDevice.current.batteryLevel)
            バッテリー状態: \(UIDevice.current.batteryState.rawValue)
            低電力モード: \(ProcessInfo.processInfo.isLowPowerModeEnabled)
            最終広告読み込み時刻: \(self.lastAdLoadTime?.description ?? "なし")
            インターフェース詳細:
            \(path.availableInterfaces.map { "- \($0.name): \($0.type)" }.joined(separator: "\n"))
            ネットワーク状態履歴:
            \(networkStatusHistory.map { "- \($0.0): \($0.1)" }.joined(separator: "\n"))
            """
            
            logger.warning("\(additionalInfo, privacy: .public)")
        }
    }
    
    // 広告の再読み込み
    private func retryLoadingAds() {
        guard self.retryCount < self.maxRetryCount else {
            logger.warning("最大再試行回数に達しました - \(self.deviceInfo)")
            self.retryCount = 0
            return
        }
        
        // 最後の広告読み込みから一定時間経過しているか確認
        if let lastLoad = self.lastAdLoadTime,
           Date().timeIntervalSince(lastLoad) < self.minimumAdLoadInterval {
            logger.info("広告読み込みの間隔が短すぎます - \(self.deviceInfo)")
            return
        }
        
        self.retryCount += 1
        logger.info("広告の再読み込みを試行 (\(self.retryCount)/\(self.maxRetryCount)) - \(self.deviceInfo)")
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(self.retryDelay * 1_000_000_000))
            await self.loadAds()
        }
    }
    
    // 広告の読み込み
    private func loadAds() async {
        guard self.isNetworkAvailable else {
            logger.warning("ネットワーク接続なし - 広告の読み込みをスキップ")
            return
        }
        
        // 接続の安定性を確認
        guard stableConnectionDuration >= 5.0 else {
            logger.info("ネットワーク接続が不安定なため、広告の読み込みを延期")
            return
        }
        
        // 最後の広告読み込みから一定時間経過しているか確認
        if let lastLoad = self.lastAdLoadTime,
           Date().timeIntervalSince(lastLoad) < self.minimumAdLoadInterval {
            logger.info("広告読み込みの間隔が短すぎます")
            return
        }
        
        self.lastAdLoadTime = Date()
        logger.info("広告読み込み開始")
        
        do {
            // インタースティシャル広告の読み込み
            self.interstitialAdManager.loadInterstitialAd()
            logger.debug("インタースティシャル広告読み込み要求完了")
            
            // リワード広告の読み込み
            self.rewardedAdManager.loadRewardedAd()
            logger.debug("リワード広告読み込み要求完了")
            
            // 接続状態をリセット
            resetConnectionState()
        } catch {
            logger.error("広告読み込みエラー: \(error.localizedDescription)")
            lastConnectionError = error
            handleConnectionLoss()
        }
    }
    
    // テストデバイスの設定
    private func configureTestDevices() {
        logger.info("テストデバイスの設定開始")
        // Note: テストデバイス設定は別の場所で行われるように変更
        logger.info("テストデバイスの設定をスキップ")
    }
    
    // 広告を表示するべきかどうかを判断
    func shouldShowAds() -> Bool {
        let shouldShow = !purchaseManager.hasRemoveAdsPurchased()
        logger.debug("広告表示判定: \(shouldShow)")
        return shouldShow
    }
    
    // タブ変更時の広告表示ロジック
    func onTabChange() {
        logger.debug("タブ変更検知 - 現在のカウンター: \(self.tabChangeCounter)")
        
        guard self.shouldShowAds() && AdConfig.FreeUserConfig.showInterstitialAds else {
            logger.debug("広告表示条件を満たしていません")
            return
        }
        
        self.tabChangeCounter += 1
        
        // 設定された頻度ごとにインタースティシャル広告を表示
        if self.tabChangeCounter >= AdConfig.interstitialAdFrequency {
            logger.info("タブ変更による広告表示条件達成")
            self.tabChangeCounter = 0
            self.showInterstitialAd()
        }
    }
    
    // インタースティシャル広告を表示
    func showInterstitialAd() {
        logger.info("インタースティシャル広告表示開始")
        
        guard self.shouldShowAds() && AdConfig.FreeUserConfig.showInterstitialAds else {
            logger.debug("広告表示条件を満たしていません")
            return
        }
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            logger.error("rootViewControllerが見つかりません")
            return
        }
        
        if interstitialAdManager.interstitialAd != nil {
            logger.debug("既存の広告を表示")
            Task { @MainActor in
                do {
                    try await interstitialAdManager.showAd(from: rootViewController)
                    logger.info("インタースティシャル広告を表示しました")
                } catch {
                    logger.error("インタースティシャル広告の表示に失敗しました: \(error.localizedDescription)")
                }
            }
        } else {
            logger.debug("新しい広告を読み込み")
            interstitialAdManager.loadInterstitialAd()
        }
    }
    
    // リワード広告を表示して結果を受け取る
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        logger.info("リワード広告表示開始")
        
        guard self.shouldShowAds() && AdConfig.FreeUserConfig.showRewardedAds else {
            logger.debug("広告表示条件を満たしていないため、報酬を自動付与")
            completion(true)
            return
        }
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            logger.error("rootViewControllerが見つかりません")
            completion(false)
            return
        }
        
        if rewardedAdManager.rewardedAd != nil {
            logger.debug("既存の広告を表示")
            rewardedAdManager.presentAd(from: rootViewController) { isRewarded in
                self.logger.info("リワード広告表示完了 - 報酬付与: \(isRewarded)")
                completion(isRewarded)
            }
        } else {
            logger.debug("新しい広告を読み込み")
            rewardedAdManager.loadRewardedAd()
            completion(false)
        }
    }
    
    // アプリ起動時に呼び出すメソッド
    func appDidLaunch() {
        logger.info("アプリ起動時の広告処理開始")
        
        if AdConfig.showInterstitialOnAppStart && self.shouldShowAds() {
            logger.debug("起動時の広告表示をスケジュール")
            // 少し遅延させて起動時に広告を表示
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(2 * 1_000_000_000))
                self.showInterstitialAd()
            }
        }
    }
    
    // ビューの表示時など、特定のタイミングで呼び出すメソッド
    func viewDidAppear(viewName: String) {
        logger.debug("ビュー表示: \(viewName)")
    }
    
    // アプリ終了時のクリーンアップ
    func cleanup() {
        logger.info("AdManagerのクリーンアップ開始")
        self.networkQualityCheckTimer?.invalidate()
        self.networkQualityCheckTimer = nil
        self.networkStabilityTimer?.invalidate()
        self.networkStabilityTimer = nil
        self.networkMonitor?.cancel()
        self.networkMonitor = nil
        logger.info("AdManagerのクリーンアップ完了")
    }
    
    deinit {
        logger.info("AdManagerのデイニシャライズ")
        Task { @MainActor in
            self.cleanup()
        }
    }
    
    // 接続失敗の処理
    private func handleConnectionFailures() {
        // QUICプロトコルを一時的に無効化
        if !isQUICDisabled {
            disableQUICProtocol()
            isQUICDisabled = true
            lastQUICDisableTime = Date()
            
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                UserDefaults.standard.set(Date(), forKey: "\(bundleIdentifier).quic_last_disable_time")
            }
            
            logger.warning("接続失敗が多発したため、QUICプロトコルを一時的に無効化")
            
            // ネットワーク設定のリセット
            Task { @MainActor in
                self.networkMonitor?.cancel()
                self.networkMonitor = nil
                self.setupNetworkMonitoring()
            }
        }
    }
    
    func showInterstitialAd(from viewController: UIViewController) {
        Task { @MainActor in
            do {
                try await interstitialAdManager.showAd(from: viewController)
                logger.info("インタースティシャル広告を表示しました")
            } catch {
                logger.error("インタースティシャル広告の表示に失敗しました: \(error.localizedDescription)")
            }
        }
    }
    
    func retryAdInitialization() {
        // Note: AdMobの初期化は別の場所で行われるように変更
        logger.info("AdMob SDKの再初期化をスキップ")
    }
}
