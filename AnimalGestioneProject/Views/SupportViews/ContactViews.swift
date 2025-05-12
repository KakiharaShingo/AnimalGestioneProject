import SwiftUI
import MessageUI

// メール送信用のラッパー
// MessageUIとSwiftUIの連携のためのラッパークラス
struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    var recipients: [String]
    var subject: String
    var messageBody: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setToRecipients(recipients)
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(messageBody, isHTML: false)
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView
        
        init(_ parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            parent.isShowing = false
            controller.dismiss(animated: true)
        }
    }
}

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
    
    // メールに関連するステート
    @State private var isShowingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    
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
                        // メール送信処理
                        submitForm()
                    }) {
                        Text("送信")
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .disabled(name.isEmpty || email.isEmpty || message.isEmpty || !MFMailComposeViewController.canSendMail())
                    
                    // メールが送信できない場合の代替オプション
                    if !MFMailComposeViewController.canSendMail() {
                        Text("メールアプリが設定されていないため、メールを送信できません。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            // メールアドレスをクリップボードにコピー
                            UIPasteboard.general.string = "sk.shingo.10@gmail.com"
                            showCopiedAlert()
                        }) {
                            Text("メールアドレスをコピーする")
                                .foregroundColor(.blue)
                        }
                    }
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
            .sheet(isPresented: $isShowingMailView) {
                // メール送信ビュー
                MailView(
                    isShowing: $isShowingMailView,
                    result: $mailResult,
                    recipients: ["sk.shingo.10@gmail.com"],
                    subject: "[お問い合わせ] " + subject,
                    messageBody: createEmailBody()
                )
            }
        }
    }
    
    // メール本文の作成
    private func createEmailBody() -> String {
        var body = "お名前: \(name)\n"
        body += "メールアドレス: \(email)\n"
        body += "カテゴリ: \(subject)\n\n"
        body += "お問い合わせ内容:\n\(message)\n\n"
        
        // デバイス情報を含める場合
        if includeDeviceInfo {
            let device = UIDevice.current
            body += "\n--- デバイス情報 ---\n"
            body += "デバイスモデル: \(device.model)\n"
            body += "デバイス名: \(device.name)\n"
            body += "OSバージョン: \(device.systemName) \(device.systemVersion)\n"
            
            // アプリのバージョン情報
            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                body += "アプリバージョン: \(appVersion) (\(buildNumber))\n"
            }
        }
        
        return body
    }
    
    // フォーム送信処理
    private func submitForm() {
        if MFMailComposeViewController.canSendMail() {
            // メールアプリが設定されている場合
            isShowingMailView = true
        } else {
            // メールアプリが設定されていない場合
            // メールアドレスをコピーするなどの代替手段を提供
            UIPasteboard.general.string = "sk.shingo.10@gmail.com"
            showCopiedAlert()
        }
    }
    
    // コピー完了アラートを表示
    private func showCopiedAlert() {
        let alert = UIAlertController(
            title: "メールアドレスをコピーしました",
            message: "sk.shingo.10@gmail.com\nお使いのメールアプリでお問い合わせを送信してください。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // アラートを表示
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            topVC.present(alert, animated: true)
        }
    }
}
