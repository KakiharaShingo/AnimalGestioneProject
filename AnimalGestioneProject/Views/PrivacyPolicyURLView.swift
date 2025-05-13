import SwiftUI

struct PrivacyPolicyURLView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("プライバシーポリシーURL")
                    .font(.title)
                    .bold()
                
                Text("このアプリのプライバシーポリシーは以下のURLで公開されています：")
                    .padding(.top)
                
                // URL表示
                VStack(alignment: .leading) {
                    Text("公開URL:")
                        .font(.headline)
                    
                    Text(URLProvider.privacyPolicyURL)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button(action: {
                        if let url = URL(string: URLProvider.privacyPolicyURL) {
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
                
                // GitHub リポジトリ情報
                VStack(alignment: .leading) {
                    Text("GitHub リポジトリ:")
                        .font(.headline)
                    
                    Text(URLProvider.gitHubRepoURL)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button(action: {
                        if let url = URL(string: URLProvider.gitHubRepoURL) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("リポジトリを開く", systemImage: "link")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
                
                Text("注意: プライバシーポリシーの内容を更新する場合は、アプリ内の表示とGitHubページの両方を更新してください。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
            .navigationTitle("プライバシーポリシーURL")
            .navigationBarItems(trailing: Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct PrivacyPolicyURLView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyURLView()
    }
}
