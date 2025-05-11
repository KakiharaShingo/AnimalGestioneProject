import SwiftUI

struct PremiumHealthCheckView: View {
    @EnvironmentObject var dataStore: CoreDataStore
    @ObservedObject var adManager = AdManager.shared
    @State private var showingRewardedModal = false
    @State private var isPremiumFeatureAvailable = false
    
    var animalId: UUID
    
    private var animal: Animal? {
        dataStore.animals.first { $0.id == animalId }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.red)
                
                Text("プレミアム健康チェック")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding(.top)
            
            // 動物情報
            if let animal = animal {
                AnimalInfoCard(animal: animal)
            }
            
            // プレミアム機能の説明
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "checkmark.circle.fill", title: "詳細な健康分析", description: "より詳細な健康データ分析とグラフ表示")
                FeatureRow(icon: "chart.xyaxis.line", title: "傾向分析", description: "体重、健康状態の長期的な傾向分析")
                FeatureRow(icon: "flag.fill", title: "健康アラート", description: "異常値検出と早期警告システム")
                FeatureRow(icon: "doc.text.fill", title: "レポート機能", description: "獣医に提供できる健康レポートの作成")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            // プレミアム機能へのアクセスボタン
            if adManager.purchaseManager.hasRemoveAdsPurchased() || isPremiumFeatureAvailable {
                // プレミアム購入済みまたは広告視聴済みの場合
                Button(action: {
                    // プレミアム機能を実行
                    performPremiumHealthCheck()
                }) {
                    Text("健康分析を開始")
                        .fontWeight(.bold)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            } else {
                // 未購入の場合は広告視聴またはプレミアム購入を提案
                Button(action: {
                    showingRewardedModal = true
                }) {
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                        Text("広告を視聴して機能を使用")
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // プレミアム機能の表示が有効な場合のみ表示
                if InAppPurchaseManager.showPremiumFeatures {
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
                        .padding(.horizontal)
                    }
                } else {
                    Text("サポートありがとうございます")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.gray)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.bottom)
        .sheet(isPresented: $showingRewardedModal) {
            // リワード広告視聴用のビュー
            RewardedFeatureView(featureName: "プレミアム健康チェック") {
                // 報酬獲得後のコールバック
                isPremiumFeatureAvailable = true
            }
        }
    }
    
    // プレミアム健康チェック機能（ダミー）
    private func performPremiumHealthCheck() {
        // ここに実際の機能を実装
        print("プレミアム健康チェックを実行: \(animal?.name ?? "不明な動物")")
        
        // この例では単純なアラートを表示する実装だけを行う
        // 実際のアプリでは、このメソッドで高度な健康チェック機能を実装する
    }
    
    // プレミアム購入画面を表示
    private func showPremiumPurchaseView() {
        // ここに実装（既存のPremiumPurchaseViewを使用）
    }
}

// 動物情報カード
struct AnimalInfoCard: View {
    let animal: Animal
    
    var body: some View {
        HStack(spacing: 15) {
            // 動物のアイコンまたは画像
            if let imageUrl = animal.imageUrl, let imageData = try? Data(contentsOf: imageUrl), let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Image(systemName: "pawprint.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(animal.color)
            }
            
            // 動物の基本情報
            VStack(alignment: .leading, spacing: 5) {
                Text(animal.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(animal.species)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    if let birthDate = animal.birthDate {
                        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
                        Label("\(age)歳", systemImage: "calendar")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    // 体重記録の取得方法に応じて修正が必要
                    // このコードはデータストアから最新の体重を取得する例
                    if let weightRecord = getLatestWeightRecord(for: animal.id) {
                        Label("\(String(format: "%.1f", weightRecord.weight ?? 0))kg", systemImage: "scalemass")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // 最新の体重記録を取得する関数
    private func getLatestWeightRecord(for animalId: UUID) -> HealthRecord? {
        // データストアからデータを取得するロジック
        // 実際の実装は、CoreDataStoreの構造に依存します
        return nil // 仮実装
    }
}

// プレビュー
struct PremiumHealthCheckView_Previews: PreviewProvider {
    static var previews: some View {
        let dataStore = CoreDataStore()
        return PremiumHealthCheckView(animalId: UUID())
            .environmentObject(dataStore)
    }
}
