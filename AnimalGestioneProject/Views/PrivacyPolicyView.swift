import SwiftUI

// AnimalGestioneProjectモジュールのパブリックビュー

public struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var agreedToPolicy = false
    
    public var isModal: Bool = false
    public var onAgree: (() -> Void)? = nil
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー
                Text("プライバシーポリシー")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                Text("最終更新日: 2025年5月11日")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // はじめに
                SectionView(title: "はじめに") {
                    Text("AnimalGestioneProject（以下、「当アプリ」といいます）は、お客様のプライバシーを尊重し、個人情報の保護に努めています。本プライバシーポリシーは、当アプリのご利用に際して収集する情報の種類、その使用方法、お客様の選択肢について説明するものです。")
                    
                    Text("当アプリをダウンロードしてご利用いただくことにより、お客様は本プライバシーポリシーに記載された方針に同意したものとみなされます。")
                }
                
                // 収集する情報
                SectionView(title: "収集する情報") {
                    Text("お客様が提供する情報")
                        .font(.headline)
                        .padding(.vertical, 5)
                    
                    Text("当アプリは、以下の情報をお客様に提供していただくことがあります：")
                    
                    PrivacyBulletPointView("ペット情報: ペットの名前、種類、品種、誕生日、性別など")
                    PrivacyBulletPointView("健康記録: 体重、体温、食欲、活動レベルなどの健康状態")
                    PrivacyBulletPointView("医療記録: ワクチン接種、健康診断、投薬の記録")
                    PrivacyBulletPointView("写真: ペットの写真（任意）")
                    
                    Text("自動的に収集される情報")
                        .font(.headline)
                        .padding(.vertical, 5)
                    
                    Text("当アプリは、以下の情報を自動的に収集することがあります：")
                    
                    PrivacyBulletPointView("デバイス情報: 使用しているデバイスの種類、オペレーティングシステム、アプリケーションバージョン")
                    PrivacyBulletPointView("使用状況データ: アプリの利用頻度、機能の使用状況、クラッシュレポート")
                    PrivacyBulletPointView("広告識別子: 広告配信のための識別子（AdMob使用時）")
                }
                
                // 情報の使用目的
                SectionView(title: "情報の使用目的") {
                    Text("収集した情報は、以下の目的で使用されます：")
                    
                    PrivacyBulletPointView("アプリの機能提供とユーザーエクスペリエンスの向上")
                    PrivacyBulletPointView("アプリのパフォーマンス分析と改善")
                    PrivacyBulletPointView("カスタマーサポートの提供")
                    PrivacyBulletPointView("パーソナライズされた通知の送信（ご希望の場合）")
                    PrivacyBulletPointView("広告の表示（無料版のみ）")
                }
                
                // 情報の保存
                SectionView(title: "情報の保存") {
                    Text("ローカルストレージ")
                        .font(.headline)
                        .padding(.vertical, 5)
                    
                    Text("当アプリで入力されたすべてのペット情報と健康記録は、お客様のデバイス上にローカルに保存され、標準設定ではサーバーにアップロードされることはありません。")
                    
                    Text("データバックアップ")
                        .font(.headline)
                        .padding(.vertical, 5)
                    
                    Text("お客様がデータのバックアップ機能を使用した場合、データは暗号化された形式で保存され、お客様がアクセスできる場所（iCloudなど）に保存されます。")
                }
                
                // 第三者とのデータ共有
                SectionView(title: "第三者とのデータ共有") {
                    Text("当アプリは、以下の場合を除き、お客様の個人情報を第三者と共有することはありません：")
                    
                    Text("サービスプロバイダー")
                        .font(.headline)
                        .padding(.vertical, 5)
                    
                    Text("当アプリは、以下のサービスプロバイダーと情報を共有することがあります：")
                    
                    PrivacyBulletPointView("Google AdMob: 広告表示のため（無料版のみ）")
                    PrivacyBulletPointView("アナリティクスプロバイダー: アプリのパフォーマンス分析のため")
                    PrivacyBulletPointView("Apple: アプリ内課金処理のため")
                    
                    Text("法的要件")
                        .font(.headline)
                        .padding(.vertical, 5)
                    
                    Text("法律の要求、規制の遵守、法的手続き、政府からの要請に応じるために必要な場合。")
                }
                
                // お客様の選択肢と権利
                SectionView(title: "お客様の選択肢と権利") {
                    Text("お客様には以下の権利があります：")
                    
                    PrivacyBulletPointView("情報へのアクセス: 当アプリに保存されているご自身の情報にアクセスする権利")
                    PrivacyBulletPointView("情報の修正: 不正確または不完全な情報を修正する権利")
                    PrivacyBulletPointView("情報の削除: アプリからご自身の情報を削除する権利")
                    PrivacyBulletPointView("通知の管理: アプリからの通知を管理・無効化する権利")
                }
                
                // データセキュリティ
                SectionView(title: "データセキュリティ") {
                    Text("当アプリは、お客様の情報を不正アクセス、改ざん、漏洩から保護するために適切な技術的・組織的対策を講じています。ただし、インターネット上またはモバイルプラットフォーム上での情報伝送は完全に安全ではないことをご了承ください。")
                }
                
                // 子どものプライバシー
                SectionView(title: "子どものプライバシー") {
                    Text("当アプリは、13歳未満の子どもから意図的に個人情報を収集することはありません。13歳未満の子どもからの情報収集に気づいた場合は、速やかに削除するための措置を講じます。")
                }
                
                // プライバシーポリシーの変更
                SectionView(title: "プライバシーポリシーの変更") {
                    Text("当アプリは、本プライバシーポリシーを随時更新することがあります。変更があった場合は、アプリ内で通知するか、更新されたプライバシーポリシーを掲載します。定期的にプライバシーポリシーを確認されることをお勧めします。")
                }
                
                // お問い合わせ
                SectionView(title: "お問い合わせ") {
                    Text("本プライバシーポリシーに関するご質問やご意見がございましたら、以下の連絡先までお問い合わせください：")
                    
                    Text("メールアドレス: sk.shingo.10@gmail.com")
                        .padding(.vertical, 5)
                }
                
                // 同意オプション（モーダル表示の場合のみ）
                if isModal {
                    VStack {
                        Toggle("上記プライバシーポリシーに同意します", isOn: $agreedToPolicy)
                            .padding()
                            .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                        
                        Button(action: {
                            if agreedToPolicy {
                                onAgree?()
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Text("続ける")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(agreedToPolicy ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(!agreedToPolicy)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitle("プライバシーポリシー", displayMode: .inline)
        .navigationBarItems(leading: 
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("閉じる")
            }
        )
    }
}

// セクションを表示するためのヘルパービュー
public struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            content
            
            Divider()
                .padding(.top, 5)
        }
    }
}

// 箇条書きテキスト用のヘルパービュー
public struct PrivacyBulletPointView: View {
    let text: String
    
    public init(_ text: String) {
        self.text = text
    }
    
    public var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .padding(.trailing, 5)
            Text(text)
            Spacer()
        }
        .padding(.leading)
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacyPolicyView()
        }
    }
}
