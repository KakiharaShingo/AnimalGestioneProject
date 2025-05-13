import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var appSetupManager = AppSetupManager.shared
    @State private var showPrivacyPolicy = false
    @State private var showPrivacyPolicyURL = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://apps.apple.com/jp/app/id123456789") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("App Storeで評価する")
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Section(header: Text("サポート")) {
                    Button(action: {
                        if let url = URLProvider.mailToURL(subject: "AnimalGestioneProject サポート問い合わせ") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("サポートに問い合わせる")
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("プライバシー")) {
                    Button(action: {
                        showPrivacyPolicy = true
                    }) {
                        HStack {
                            Text("プライバシーポリシー")
                            Spacer()
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        showPrivacyPolicyURL = true
                    }) {
                        HStack {
                            Text("プライバシーポリシーURL (開発者用)")
                            Spacer()
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("データ管理")) {
                    NavigationLink(destination: DataManagementView()) {
                        HStack {
                            Text("データのエクスポート/インポート")
                            Spacer()
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("設定")
            .navigationBarItems(trailing: Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showPrivacyPolicy) {
                EmbeddedPrivacyPolicyView()
            }
            .sheet(isPresented: $showPrivacyPolicyURL) {
                PrivacyPolicyURLView()
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
