import SwiftUI

// SimplePrivacyConsentViewの代替実装
struct SimplePrivacyConsentView: View {
    @Binding var showConsentView: Bool
    @State private var agreedToPolicy = false
    @State private var showingFullPolicy = false
    
    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.top, 30)
            
            Text("プライバシーポリシー")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("AnimalGestioneProjectへようこそ")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // プライバシーポリシーの概要
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("当アプリは、以下の情報を収集します：")
                        .font(.headline)
                    
                    // 箇条書きリスト
                    BulletPointItem("ペット情報（名前、種類、品種、誕生日、性別など）")
                    BulletPointItem("健康記録（体重、体温、食欲、活動レベルなど）")
                    BulletPointItem("医療記録（ワクチン接種、健康診断、投薬の記録）")
                    BulletPointItem("デバイス情報と使用状況データ")
                    
                    Text("収集した情報の使用目的：")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    // 箇条書きリスト
                    BulletPointItem("アプリの機能提供とユーザーエクスペリエンスの向上")
                    BulletPointItem("アプリのパフォーマンス分析と改善")
                    BulletPointItem("パーソナライズされた通知の送信（ご希望の場合）")
                    BulletPointItem("広告の表示（無料版のみ）")
                    
                    Text("お客様のデータはお使いのデバイス上にローカル保存され、標準設定ではサーバーにアップロードされません。")
                        .padding(.top, 10)
                        .lineLimit(nil)
                    
                    Button(action: {
                        showingFullPolicy = true
                    }) {
                        Text("プライバシーポリシーの全文を読む")
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .padding(.top, 15)
                }
                .padding()
            }
            .frame(height: 300)
            .background(Color(.systemGroupedBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // 同意トグル
            Toggle("上記プライバシーポリシーに同意します", isOn: $agreedToPolicy)
                .padding()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            // 同意ボタン
            Button(action: {
                if agreedToPolicy {
                    // UserDefaultsに同意を保存
                    UserDefaults.standard.set(true, forKey: "privacyPolicyAccepted")
                    UserDefaults.standard.set(Date(), forKey: "privacyPolicyAcceptedDate")
                    
                    // 画面を閉じる
                    showConsentView = false
                }
            }) {
                Text("同意して続ける")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(agreedToPolicy ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!agreedToPolicy)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showingFullPolicy) {
            NavigationView {
                PrivacyPolicyView()
                    .navigationBarItems(leading: Button("閉じる") {
                        showingFullPolicy = false
                    })
            }
        }
    }
}

// 箇条書き用の新しいヘルパービュー
struct BulletPointItem: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .padding(.trailing, 5)
            Text(text)
            Spacer()
        }
        .padding(.leading)
    }
}

struct SimplePrivacyConsent_Previews: PreviewProvider {
    static var previews: some View {
        SimplePrivacyConsentView(showConsentView: .constant(true))
    }
}
