import SwiftUI
import StoreKit

/// プレミアムサブスクリプション購入ビュー
struct PremiumSubscriptionView: View {
    @StateObject private var viewModel = PremiumSubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // ヘッダー部分
                    headerSection
                    
                    // 機能説明
                    featuresSection
                    
                    // 商品選択
                    productsSection
                    
                    // 購入復元ボタン
                    restoreButton
                    
                    // 利用規約とプライバシーポリシー
                    legalSection
                }
                .padding()
            }
            .navigationTitle("プレミアムプラン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("お知らせ", isPresented: $viewModel.showAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.alertMessage)
            }
            .task {
                // ビュー表示時に商品情報を更新
                await viewModel.loadProducts()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissPremiumView"))) { _ in
                dismiss()
            }
        }
    }
    
    // ヘッダー部分
    private var headerSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "crown.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.yellow)
                .padding(.top)
            
            Text("プレミアムにアップグレード")
                .font(.title)
                .fontWeight(.bold)
            
            Text("すべての機能を利用して、より充実したペット管理を")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // 機能説明
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("プレミアム特典")
                .font(.headline)
                .padding(.bottom, 5)
            
            PremiumFeatureRow(icon: "xmark.circle.fill", title: "広告非表示", description: "アプリ内の広告をすべて非表示にします")
            PremiumFeatureRow(icon: "plus.circle.fill", title: "ペット登録無制限", description: "無制限の数のペットを登録できます")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // 商品選択部分
    private var productsSection: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if !viewModel.products.isEmpty {
                ForEach(viewModel.products, id: \.id) { product in
                    SubscriptionOptionCard(
                        product: product,
                        isLoading: viewModel.purchasingProduct == product.id,
                        isPurchased: viewModel.subscriptionManager.isPurchased(product.id),
                        onPurchase: {
                            Task {
                                await viewModel.purchase(product)
                            }
                        }
                    )
                    .padding(.vertical, 5)
                }
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("商品情報を読み込んでいます...")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    // 購入復元ボタン
    private var restoreButton: some View {
        Button(action: {
            Task {
                await viewModel.restorePurchases()
            }
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("過去の購入を復元")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(10)
        }
        .disabled(viewModel.isLoading || viewModel.isPurchasing)
    }
    
    // 利用規約部分
    private var legalSection: some View {
        VStack(spacing: 10) {
            Text("サブスクリプションは自動更新され、Appleの課金システムにより課金されます。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("期間終了の24時間前までにキャンセルしない限り自動更新されます。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack {
                Link("利用規約", destination: URL(string: "https://example.jp/terms")!)
                Text("・")
                Link("プライバシーポリシー", destination: URL(string: "https://example.jp/privacy")!)
            }
            .font(.caption)
            .padding(.top, 5)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

/// 機能説明行コンポーネント
struct PremiumFeatureRow: View {
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

/// サブスクリプションオプションカード
struct SubscriptionOptionCard: View {
    let product: Product
    let isLoading: Bool
    let isPurchased: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // カード内容
            HStack {
                // 商品情報
                VStack(alignment: .leading, spacing: 5) {
                    Text(getLocalizedProductName(product))
                        .font(.headline)
                    
                    if let subscription = product.subscription {
                        Text(formatSubscriptionPeriod(subscription.subscriptionPeriod))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let promotionalText = getPromotionalText(for: product) {
                        Text(promotionalText)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                // 価格
                VStack(alignment: .trailing) {
                    if isPurchased {
                        Text("購入済み")
                            .font(.headline)
                            .foregroundColor(.green)
                    } else {
                        Text(product.displayPrice)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .background(
                isPurchased ? 
                Color.green.opacity(0.1) : 
                (product.id.contains("yearly") ? Color.blue.opacity(0.1) : Color(.systemGray5))
            )
            
            // 購入ボタン
            if !isPurchased {
                Button(action: onPurchase) {
                    HStack {
                        Text(isLoading ? "処理中..." : "購入")
                        if isLoading {
                            ProgressView()
                                .padding(.leading, 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                }
                .disabled(isLoading)
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isPurchased ? Color.green : 
                    (product.id.contains("yearly") ? Color.blue : Color.gray),
                    lineWidth: 1
                )
        )
    }
    
    // 商品名を日本語で取得
    private func getLocalizedProductName(_ product: Product) -> String {
        if product.id.contains("monthly") {
            return "月額プレミアム"
        } else if product.id.contains("yearly") {
            return "年間プレミアム"
        } else if product.id.contains("lifetime") {
            return "永久プレミアム"
        }
        return product.localizedName
    }
    
    // サブスクリプション期間を日本語でフォーマット
    private func formatSubscriptionPeriod(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            return "\(period.value)日間"
        case .week:
            return "\(period.value)週間"
        case .month:
            return "\(period.value)ヶ月間"
        case .year:
            return "\(period.value)年間"
        @unknown default:
            return "\(period.value) 単位"
        }
    }
    
    // プロモーションテキストを取得
    private func getPromotionalText(for product: Product) -> String? {
        if product.id.contains("yearly") {
            return "年間プランが最もお得です（2ヶ月分無料）"
        }
        if product.id.contains("lifetime") {
            return "一度のお支払いで永久に使えます"
        }
        return nil
    }
}

/// プレミアムサブスクリプションビューモデル
class PremiumSubscriptionViewModel: ObservableObject {
    let subscriptionManager = SubscriptionManager.shared
    
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var purchasingProduct: String? = nil
    @Published var errorMessage: String? = nil
    
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    /// 商品情報を読み込む
    func loadProducts() async {
        // 既に読み込み済みなら処理しない
        if !products.isEmpty {
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // SubscriptionManagerから商品情報を更新させる
            await subscriptionManager.loadProducts()
            
            // 商品情報を取得してソート
            await MainActor.run {
                self.products = sortProducts(subscriptionManager.products)
                self.isLoading = false
            }
            
            if products.isEmpty {
                await MainActor.run {
                    self.errorMessage = "利用可能な商品が見つかりませんでした"
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "商品情報の読み込みに失敗しました"
                self.isLoading = false
            }
        }
    }
    
    /// 商品の購入処理
    func purchase(_ product: Product) async {
        await MainActor.run {
            isPurchasing = true
            purchasingProduct = product.id
        }
        
        do {
            // 商品を購入
            let transaction = try await subscriptionManager.purchase(product)
            
            await MainActor.run {
                if transaction != nil {
                    // 購入成功
                    alertMessage = "ご購入ありがとうございます！プレミアム機能がご利用いただけます。"
                    showAlert = true
                    
                    // 購入後に即座に親コンポーネントに通知
                    // 購入完了を通知する
                    NotificationCenter.default.post(name: NSNotification.Name("PremiumPurchaseCompleted"), object: nil)
                    
                    // 画面を閉じる通知も送信
                    NotificationCenter.default.post(name: NSNotification.Name("DismissPremiumView"), object: nil)
                }
                isPurchasing = false
                purchasingProduct = nil
            }
        } catch {
            await MainActor.run {
                alertMessage = "購入処理中にエラーが発生しました"
                showAlert = true
                isPurchasing = false
                purchasingProduct = nil
            }
        }
    }
    
    /// 購入の復元処理
    func restorePurchases() async {
        await MainActor.run {
            isPurchasing = true
        }
        
        do {
            // 購入を復元
            try await subscriptionManager.restorePurchases()
            
            await MainActor.run {
                if subscriptionManager.hasActiveSubscription {
                    alertMessage = "購入が復元されました！"
                    // 復元成功時にプレミアムステータス変更通知を送信
                    NotificationCenter.default.post(name: NSNotification.Name("PremiumPurchaseCompleted"), object: nil)
                    // 画面を閉じる通知も送信
                    NotificationCenter.default.post(name: NSNotification.Name("DismissPremiumView"), object: nil)
                } else {
                    alertMessage = "復元できる購入はありませんでした。"
                }
                showAlert = true
                isPurchasing = false
            }
        } catch {
            await MainActor.run {
                alertMessage = "購入の復元中にエラーが発生しました"
                showAlert = true
                isPurchasing = false
            }
        }
    }
    
    /// 商品を適切な順序に並べ替え
    private func sortProducts(_ products: [Product]) -> [Product] {
        // 最初に一時購入、次に年間サブスク、最後に月間サブスクの順序で表示
        return products.sorted { product1, product2 in
            if product1.id.contains("lifetime") {
                return true
            } else if product2.id.contains("lifetime") {
                return false
            } else if product1.id.contains("yearly") {
                return true
            } else if product2.id.contains("yearly") {
                return false
            } else {
                return true
            }
        }
    }
}