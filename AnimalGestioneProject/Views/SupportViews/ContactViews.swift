import SwiftUI

// お問い合わせビュー
struct ContactSupportView: View {
    @Binding var showingContactForm: Bool
    
    var body: some View {
        VStack(spacing: 25) {
            // ヘッダーイメージ
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue)
                .padding(.top, 30)
            
            Text("サポートが必要ですか？")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("技術的な問題や機能追加の要望など、お気軽にお問い合わせください。サポートチームが対応いたします。")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            // お問い合わせボタン
            Button(action: {
                showingContactForm = true
            }) {
                Text("お問い合わせフォームを開く")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // その他のサポートオプション
            GroupBox(label: 
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("その他のサポートオプション")
                        .font(.headline)
                }
            ) {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "envelope")
                            .frame(width: 30)
                        Text("sk.shingo.10@gmail.com")
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "globe")
                            .frame(width: 30)
                        Text("www.animalgestioneproject.com/support")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "doc.text")
                            .frame(width: 30)
                        Text("よくある質問（FAQ）を確認する")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
                .padding(.vertical, 10)
            }
            .padding()
            
            Spacer()
        }
    }
}

// お問い合わせフォーム
struct ContactFormView: View {
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var email = ""
    @State private var subject = "技術的な問題"
    @State private var message = ""
    @State private var includeDeviceInfo = true
    @State private var showingConfirmation = false
    
    let subjectOptions = ["技術的な問題", "機能追加の要望", "その他の質問", "バグの報告"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("お客様情報")) {
                    TextField("お名前", text: $name)
                    TextField("メールアドレス", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("お問い合わせ内容")) {
                    Picker("カテゴリ", selection: $subject) {
                        ForEach(subjectOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("詳細なご説明をお願いします...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $message)
                            .frame(minHeight: 150)
                            .opacity(message.isEmpty ? 0.25 : 1)
                    }
                }
                
                Section(footer: Text("デバイス情報を含めることで、より正確なサポートが提供できます。")) {
                    Toggle("デバイス情報を含める", isOn: $includeDeviceInfo)
                }
                
                Section {
                    Button(action: {
                        // フォーム送信処理
                        submitForm()
                    }) {
                        Text("送信")
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .disabled(name.isEmpty || email.isEmpty || message.isEmpty)
                }
            }
            .navigationBarTitle("お問い合わせ", displayMode: .inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    isPresented = false
                }
            )
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("送信完了"),
                    message: Text("お問い合わせを受け付けました。通常2営業日以内に返信いたします。"),
                    dismissButton: .default(Text("OK")) {
                        isPresented = false
                    }
                )
            }
        }
    }
    
    private func submitForm() {
        // ここでは送信が成功したと想定してアラートを表示
        // 実際の実装では、メール送信やサーバーへのデータ送信などの処理を行う
        showingConfirmation = true
    }
}
