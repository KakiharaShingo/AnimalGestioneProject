import SwiftUI

/// 広告表示エリアのコンテナビュー。有料版の場合は表示されない
struct AdContainerView: View {
    @ObservedObject private var adManager = AdManager.shared
    @ObservedObject private var purchaseManager = InAppPurchaseManager.shared
    
    // 自分自身の更新用トリガー
    @State private var updateTrigger = UUID()
    @State private var isAdLoaded = false // 広告の読み込み状態を追跡
    @State private var loadAttempts = 0 // 読み込み試行回数
    
    // デバイスタイプに応じた広告高さ
    var adHeight: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 90 // iPad用のリーダーボードサイズ
        } else {
            return 50 // iPhone用のバナーサイズ
        }
    }
    
    // メニューからの余白（デバイスタイプに応じて調整）
    var menuPadding: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 10 // iPad用の余白
        } else {
            return 60 // iPhone用の余白（タブバーの高さに合わせて調整）
        }
    }
    
    // 有料版購入状態に基づいて高さを動的に決定
    var displayHeight: CGFloat {
        shouldShowAds ? adHeight : 0
    }
    
    // 広告を表示すべきかどうか
    var shouldShowAds: Bool {
        adManager.shouldShowAds() && AdConfig.FreeUserConfig.showBannerAds
    }
    
    var body: some View {
        Group {
            if shouldShowAds {
                // 広告を表示
                VStack(spacing: 0) {
                    Spacer()
                    
                    ZStack {
                        BannerAdView(adUnitID: AdConfig.bannerAdUnitId, onAdLoaded: { loaded in
                            isAdLoaded = loaded
                            if !loaded {
                                loadAttempts += 1
                                // 3回失敗したら少し待ってから再試行
                                if loadAttempts >= 3 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        updateTrigger = UUID()
                                        loadAttempts = 0
                                    }
                                }
                            } else {
                                loadAttempts = 0
                            }
                        })
                        .frame(height: adHeight)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemBackground))
                        .transition(.opacity)
                        .animation(.easeInOut, value: shouldShowAds)
                        
                        if !isAdLoaded {
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .frame(width: 30, height: 30)
                                if loadAttempts > 0 {
                                    Text("広告を読み込み中...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, menuPadding)
            } else {
                // プレミアムユーザーの場合は表示なし
                EmptyView()
                    .frame(height: 0)
            }
        }
        // プレミアムステータスが変更されたときに再読み込み
        .onChange(of: purchaseManager.debugPremiumEnabled) { _ in
            // ビューを強制更新
            updateTrigger = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PremiumStatusChanged"))) { _ in
            // ビューを強制更新
            updateTrigger = UUID()
        }
        // 下記のモディファイアは実際には表示されませんが、ステートの変更をビューに伝えるために必要です
        .id(updateTrigger)
    }
}

// タブバー下部に広告表示するための拡張ビュー
struct TabBarAdView: View {
    @ObservedObject private var adManager = AdManager.shared
    @State private var isAdLoaded = false
    @State private var loadAttempts = 0
    
    var shouldShowAds: Bool {
        adManager.shouldShowAds() && AdConfig.FreeUserConfig.showBannerAds
    }
    
    // デバイスタイプに応じた広告高さ
    var adHeight: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 90 // iPad用のリーダーボードサイズ
        } else {
            return 50 // iPhone用のバナーサイズ
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            if shouldShowAds {
                ZStack {
                    BannerAdView(adUnitID: AdConfig.bannerAdUnitId, onAdLoaded: { loaded in
                        isAdLoaded = loaded
                        if !loaded {
                            loadAttempts += 1
                            // 3回失敗したら少し待ってから再試行
                            if loadAttempts >= 3 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    loadAttempts = 0
                                }
                            }
                        } else {
                            loadAttempts = 0
                        }
                    })
                    .frame(height: adHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: shouldShowAds)
                    
                    if !isAdLoaded {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(width: 30, height: 30)
                            if loadAttempts > 0 {
                                Text("広告を読み込み中...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.clear)
    }
}

// プレビュー
struct AdContainerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("メインコンテンツ")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            AdContainerView()
        }
    }
}
