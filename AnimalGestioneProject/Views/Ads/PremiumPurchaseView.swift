import SwiftUI
import StoreKit

struct PremiumPurchaseView: View {
    @EnvironmentObject var purchaseManager: InAppPurchaseManager
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // ヘッダー画像
                Image(systemName: "crown.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.yellow)
                    .padding(.top, 20)
                
                // タイトル
                Text("プレミアムにアップグレード")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // 特典の説明
                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(icon: "xmark.circle.fill", title: "広告非表示", description: "アプリ内の広告をすべて非表示にします")
                    FeatureRow(icon: "plus.circle.fill", title: "新機能へのアクセス", description: "今後追加される予定の機能にアクセスできます")
                    FeatureRow(icon: "heart.circle.fill", title: "開発者をサポート", description: "アプリ開発の継続をサポートできます")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // 購入ボタン
                if purchaseManager.hasRemoveAdsPurchased() {
                    Text("プレミアム購入済み")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                } else {
                    if purchaseManager.products.isEmpty && !isProcessing {
                        Button("製品情報を読み込む") {
                            loadProducts()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    } else if isProcessing {
                        ProgressView()
                            .padding()
                    } else {
                        ForEach(purchaseManager.products, id: \.productIdentifier) { product in
                            Button(action: {
                                purchaseProduct(product)
                            }) {
                                HStack {
                                    Text("プレミアムを購入")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text(product.priceLocale.currencySymbol ?? "" + product.price.stringValue)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        
                        Button("過去の購入を復元") {
                            restorePurchases()
                        }
                        .font(.subheadline)
                        .padding(.vertical)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(errorMessage?.contains("成功") == true ? "成功" : "エラー"),
                    message: Text(errorMessage ?? "不明なエラーが発生しました"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                loadProducts()
            }
        }
    }
    
    private func loadProducts() {
        isProcessing = true
        purchaseManager.requestProducts()
        
        // リクエスト完了の監視
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
        }
    }
    
    private func purchaseProduct(_ product: SKProduct) {
        isProcessing = true
        
        purchaseManager.purchase(product: product) { result in
            isProcessing = false
            
            switch result {
            case .success:
                errorMessage = "購入が成功しました！広告が非表示になりました。"
                showAlert = true
            case .failure(let error):
                errorMessage = "購入に失敗しました: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func restorePurchases() {
        isProcessing = true
        
        purchaseManager.restorePurchases { result in
            isProcessing = false
            
            switch result {
            case .success:
                if purchaseManager.hasRemoveAdsPurchased() {
                    errorMessage = "購入が復元されました！広告が非表示になりました。"
                } else {
                    errorMessage = "復元できる購入はありませんでした。"
                }
                showAlert = true
            case .failure(let error):
                errorMessage = "購入の復元に失敗しました: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

// 特典の説明用の行コンポーネント
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PremiumPurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPurchaseView()
            .environmentObject(InAppPurchaseManager.shared)
    }
}
