import SwiftUI

/// 広告表示エリアのコンテナビュー。有料版の場合は表示されない
struct AdContainerView: View {
    @ObservedObject private var adManager = AdManager.shared
    @ObservedObject private var purchaseManager = InAppPurchaseManager.shared
    
    // 自分自身の更新用トリガー
    @State private var updateTrigger = UUID()
    
    // 固定の広告高さ
    let adHeight: CGFloat = 50
    // メニューからの余白
    let menuPadding: CGFloat = 60 // タブバーの高さに合わせて調整
    
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
                    
                    BannerAdView(adUnitID: AdConfig.bannerAdUnitId)
                        .frame(height: adHeight)
                        .transition(.opacity)
                        .animation(.easeInOut, value: shouldShowAds)
                }
                .padding(.bottom, menuPadding) // メニューが隔やらないように下部に余白を追加
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
    
    var shouldShowAds: Bool {
        adManager.shouldShowAds() && AdConfig.FreeUserConfig.showBannerAds
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            if shouldShowAds {
                BannerAdView(adUnitID: AdConfig.bannerAdUnitId)
                    .frame(height: 50)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: shouldShowAds)
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
