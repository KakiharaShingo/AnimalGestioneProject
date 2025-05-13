import SwiftUI

struct SupportURLView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("サポートURL")
                    .font(.title)
                    .bold()
                
                Text("このアプリのサポートページは以下のURLで公開されています：")
                    .padding(.top)
                
                // URL表示
                VStack(alignment: .leading) {
                    Text("公開URL:")
                        .font(.headline)
                    
                    Text(URLProvider.supportURL)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button(action: {
                        if let url = URL(string: URLProvider.supportURL) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("ブラウザで開く", systemImage: "safari")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical)
                
                // メールでの問い合わせ
                VStack(alignment: .leading) {
                    Text("メールでの問い合わせ:")
                        .font(.headline)
                    
                    Text(URLProvider.supportEmail)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button(action: {
                        if let url = URLProvider.mailToURL(subject: "AnimalGestioneProject サポート問い合わせ") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("メールを送信", systemImage: "envelope")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
                
                Text("注意: サポートページの内容を更新する場合は、アプリ内の表示とGitHubページの両方を更新してください。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
            .navigationTitle("サポートURL")
            .navigationBarItems(trailing: Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct SupportURLView_Previews: PreviewProvider {
    static var previews: some View {
        SupportURLView()
    }
}
