import SwiftUI
import UIKit

struct DataManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var dataManager = DataExportImportManager.shared
    @EnvironmentObject var dataStore: CoreDataStore
    
    @State private var showingDocumentPicker = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedBackup: URL?
    @State private var showingImportConfirmation = false
    @State private var backupFiles: [URL] = []
    @State private var showingDeleteAllConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                // データエクスポートセクション
                Section(header: Text("バックアップ作成")) {
                    Button(action: {
                        if let url = dataManager.exportData() {
                            // エクスポート成功
                            selectedBackup = url
                            showingShareSheet = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("新しいバックアップを作成")
                        }
                    }
                    .disabled(dataManager.isExporting)
                    
                    if let lastBackup = dataManager.lastBackupDate {
                        HStack {
                            Text("最終バックアップ")
                            Spacer()
                            Text(formattedDate(lastBackup))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if dataManager.isExporting {
                        HStack {
                            Text("バックアップ中...")
                            Spacer()
                            ProgressView()
                        }
                    }
                    
                    if let error = dataManager.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // データインポートセクション
                Section(header: Text("バックアップファイルのインポート")) {
                    Button(action: {
                        showingDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                            Text("ファイルからインポート")
                        }
                    }
                    .disabled(dataManager.isImporting)
                    
                    if dataManager.isImporting {
                        HStack {
                            Text("インポート中...")
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                
                // 既存のバックアップファイル一覧
                Section(header: Text("バックアップファイル")) {
                    ForEach(backupFiles, id: \.absoluteString) { url in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(url.lastPathComponent)
                                    .font(.subheadline)
                                if let date = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                                    Text(formattedDate(date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedBackup = url
                                showingImportConfirmation = true
                            }) {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                selectedBackup = url
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.green)
                            }
                            
                            Button(action: {
                                selectedBackup = url
                                showingDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if backupFiles.isEmpty {
                        Text("バックアップファイルがありません")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
                
                // データ削除セクション
                Section(header: Text("データ管理"), footer: Text("警告：すべてのデータを削除すると、保存したすべての情報が完全に消去されます。この操作は元に戻せません。")) {
                    Button(action: {
                        showingDeleteAllConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("すべてのデータを削除")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("データ管理")
            .navigationBarItems(leading: Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                refreshBackupFiles()
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerView { url in
                    importBackup(from: url)
                }
            }
            .alert(isPresented: $showingImportConfirmation) {
                Alert(
                    title: Text("バックアップのインポート"),
                    message: Text("このバックアップをインポートしますか？現在のデータはすべて置き換えられます。"),
                    primaryButton: .destructive(Text("インポート")) {
                        if let url = selectedBackup {
                            importBackup(from: url)
                        }
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("バックアップの削除"),
                    message: Text("このバックアップファイルを削除しますか？"),
                    primaryButton: .destructive(Text("削除")) {
                        if let url = selectedBackup, dataManager.deleteBackup(url: url) {
                            refreshBackupFiles()
                        }
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
            .alert(isPresented: $showingDeleteAllConfirmation) {
                Alert(
                    title: Text("全データの削除"),
                    message: Text("本当にすべてのデータを削除しますか？この操作は元に戻せません。"),
                    primaryButton: .destructive(Text("削除")) {
                        deleteAllData()
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
        }
        .background(
            // ShareSheetを表示するための隠しビュー
            EmptyView().sheet(isPresented: $showingShareSheet) {
                if let url = selectedBackup {
                    ShareSheet(activityItems: [url])
                }
            }
        )
    }
    
    // バックアップファイル一覧を更新
    private func refreshBackupFiles() {
        backupFiles = dataManager.getAvailableBackups()
    }
    
    // バックアップファイルをインポート
    private func importBackup(from url: URL) {
        dataManager.importData(from: url) { success, message in
            if success {
                // データを再読み込み
                dataStore.loadData()
            }
        }
    }
    
    // すべてのデータを削除
    private func deleteAllData() {
        let context = PersistenceController.shared.container.viewContext
        
        // すべてのエンティティを削除
        let entities = ["Animal", "VaccineRecord", "CheckupRecord", "GroomingRecord", "WeightRecord", "PhysiologicalCycle"]
        
        for entityName in entities {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try PersistenceController.shared.container.persistentStoreCoordinator.execute(deleteRequest, with: context)
            } catch {
                print("エンティティの削除エラー \(entityName): \(error)")
            }
        }
        
        // 変更を保存
        do {
            try context.save()
            dataStore.loadData() // データストアを更新
        } catch {
            print("コンテキスト保存エラー: \(error)")
        }
    }
    
    // 日付のフォーマット
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// UIActivityViewControllerのラッパー
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 更新は不要
    }
}

// プレビュー
struct DataManagementView_Previews: PreviewProvider {
    static var previews: some View {
        DataManagementView()
            .environmentObject(CoreDataStore())
    }
}
