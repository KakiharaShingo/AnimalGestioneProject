import StoreKit
import Foundation

/// StoreKit 2関連の拡張機能
extension Product {
    /// 表示用の商品名（日本語等のローカライズ対応）
    var localizedName: String {
        return self.id.components(separatedBy: ".").last?.replacingOccurrences(of: "_", with: " ").capitalized ?? self.id
    }
    
    /// 表示用の価格（日本円表示）
    var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        
        return formatter.string(from: self.price as NSDecimalNumber) ?? "\(self.price)円"
    }
}

/// サブスクリプション期間に関する拡張機能
extension Product.SubscriptionPeriod {
    /// サブスクリプション期間の日本語表示
    var localizedDescription: String {
        switch self.unit {
        case .day:
            return self.value == 1 ? "日単位" : "\(self.value)日間"
        case .week:
            return self.value == 1 ? "週単位" : "\(self.value)週間"
        case .month:
            return self.value == 1 ? "月単位" : "\(self.value)ヶ月間"
        case .year:
            return self.value == 1 ? "年単位" : "\(self.value)年間"
        @unknown default:
            return "\(self.value)単位"
        }
    }
}

/// StoreKit 2による購入検証結果の拡張
extension VerificationResult where SignedType == StoreTransaction {
    /// トランザクションが有効かどうかを確認
    var isValid: Bool {
        switch self {
        case .verified:
            return true
        case .unverified:
            return false
        }
    }
    
    /// 検証済みトランザクションを取得（無効な場合はnilを返す）
    var transaction: StoreTransaction? {
        switch self {
        case .verified(let transaction):
            return transaction
        case .unverified:
            return nil
        }
    }
}

/// テスト用のStoreKit設定ファイル作成方法
///
/// 1. Xcodeで「File > New > File」を選択
/// 2. "StoreKit Configuration File"を選択して追加
/// 3. 以下のような商品を設定
///   - ID: com.yourdomain.animalgestione.premium_monthly
///     - タイプ: Auto-Renewable Subscription
///     - 表示名: 月額プレミアム
///     - 価格: 480円
///     - サブスクリプション期間: 1ヶ月
///   - ID: com.yourdomain.animalgestione.premium_yearly
///     - タイプ: Auto-Renewable Subscription
///     - 表示名: 年間プレミアム
///     - 価格: 4800円
///     - サブスクリプション期間: 1年
///   - ID: com.yourdomain.animalgestione.premium_lifetime
///     - タイプ: Non-Consumable
///     - 表示名: 永久プレミアム
///     - 価格: 9800円
///
/// 4. スキームエディタでこの設定ファイルを選択
///   - Product > Scheme > Edit Scheme
///   - Run > Options > StoreKit Configuration
