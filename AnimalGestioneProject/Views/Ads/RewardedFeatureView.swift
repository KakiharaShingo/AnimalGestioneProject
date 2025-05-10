import SwiftUI
import GoogleMobileAds

struct RewardedFeatureView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var adManager = AdManager.shared
    
    let featureName: String
    let onRewardEarned: () -> Void
    
    @State private var isShowingAd = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 25) {
            // アイコンと説明
            Image(systemName: "gift.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.yellow)
            
            Text("\(featureName)機能を使用")
                .font(.title)
                .fontWeight(.bold)
            
            Text("広告を視聴して\(featureName)機能を無料で使用できます。または、プレミアムへのアップグレードですべての機能を制限なく利用できます。")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // 広告視聴ボタン
            Button(action: {
                watchRewardedAd()
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("広告を視聴して使用")
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            .padding(.horizontal)
            
            // プレミアム購入ボタン
            Button(action: {
                // プレミアム購入画面を表示
                showPremiumPurchaseView()
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("プレミアムへアップグレード")
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // キャンセルボタン
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("キャンセル")
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 20)
        }
        .padding()
        .fullScreenCover(isPresented: $isShowingAd, content: {
            // リワード広告表示用のビュー
            RewardedAdView(adManager: adManager.rewardedAdManager) { isRewarded in
                if isRewarded {
                    // 報酬獲得成功
                    onRewardEarned()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    // 報酬獲得失敗
                    errorMessage = "広告の視聴が完了しませんでした。もう一度お試しください。"
                    showError = true
                }
            }
        })
        .sheet(isPresented: .constant(false)) {
            // プレミアム購入画面（ここではダミー）
            PremiumPurchaseView()
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("エラー"),
                message: Text(errorMessage ?? "不明なエラーが発生しました"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // リワード広告を視聴する
    private func watchRewardedAd() {
        isLoading = true
        
        // 広告がロードされているか確認
        if adManager.rewardedAdManager.rewardedAd != nil {
            isShowingAd = true
            isLoading = false
        } else {
            // 広告がロードされていない場合は再読み込み
            adManager.rewardedAdManager.loadRewardedAd()
            
            // 少し待ってから再確認
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isLoading = false
                if adManager.rewardedAdManager.rewardedAd != nil {
                    isShowingAd = true
                } else {
                    errorMessage = "広告の読み込みに失敗しました。ネットワーク接続を確認して、もう一度お試しください。"
                    showError = true
                }
            }
        }
    }
    
    // プレミアム購入画面を表示
    private func showPremiumPurchaseView() {
        // ここではモーダルビューとして表示するコードを追加
        // 具体的な実装は既存のPremiumPurchaseViewを利用
    }
}

// プレビュー用
struct RewardedFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        RewardedFeatureView(featureName: "プレミアム") {
            print("報酬獲得！")
        }
    }
}
