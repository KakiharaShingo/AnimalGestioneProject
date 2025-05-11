import SwiftUI
import UIKit
import CoreData

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
    @State private var showingBackupActionSheet = false
    
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
                Section(header: Text("バックアップファイル"), footer: Text("バックアップファイルをタップして操作を選択できます。")) {
                ForEach(0..<backupFiles.count, id: \.self) { index in
                    let url = backupFiles[index]
                    VStack(alignment: .leading, spacing: 4) {
                        Text(url.lastPathComponent)
                            .font(.subheadline)
                        if let date = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                            Text(formattedDate(date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                            Text(formatFileSize(fileSize))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedBackup = url
                        showingBackupActionSheet = true
                    }
                }
                    
                    if backupFiles.isEmpty {
                        Text("バックアップファイルがありません")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
                
                // データ削除セクション
                Section(header: Text("データ管理"), footer: Text("警告：「すべてのデータを削除」を選択すると、アプリ内のすべての情報（動物データ、健康記録、予定、写真など）が完全に消去されます。削除されたデータはバックアップからも回復できません。この操作は元に戻せません。")) {
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
                    message: Text(selectedBackup != nil ? "このバックアップファイルを削除しますか？\n\nファイル名：\n\(selectedBackup!.lastPathComponent)" : "バックアップを削除しますか？"),
                    primaryButton: .destructive(Text("削除")) {
                        if let url = selectedBackup {
                            if dataManager.deleteBackup(url: url) {
                                // ファイル一覧を再読み込み
                                refreshBackupFiles()
                            }
                        }
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
            .alert(isPresented: $showingDeleteAllConfirmation) {
                Alert(
                    title: Text("全データの削除"),
                    message: Text("本当にアプリ内のすべてのデータを削除しますか？\n\n・すべての動物情報\n・健康記録\n・予防接種履歴\n・写真・画像\n・その他すべてのデータ\n\nこれらの情報は完全に削除され、バックアップからも回復できません。この操作は元に戻せません。"),
                    primaryButton: .destructive(Text("すべてのデータを削除")) {
                        deleteAllData()
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
            .actionSheet(isPresented: $showingBackupActionSheet) {
                guard let url = selectedBackup else {
                    return ActionSheet(
                        title: Text("エラー"),
                        message: Text("ファイルを選択できませんでした"),
                        buttons: [.cancel()]
                    )
                }
                
                return ActionSheet(
                    title: Text("バックアップファイルの操作"),
                    message: Text(url.lastPathComponent),
                    buttons: [
                        .default(Text("インポート")) {
                            showingImportConfirmation = true
                        },
                        .default(Text("共有")) {
                            // シェアシートを表示
                            showingShareSheet = true
                        },
                        .destructive(Text("削除")) {
                            showingDeleteAlert = true
                        },
                        .cancel()
                    ]
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
        // バックアップファイル一覧を取得
        DispatchQueue.global(qos: .userInitiated).async { 
            let files = dataManager.getAvailableBackups()
            
            DispatchQueue.main.async { [self] in
                backupFiles = files
                print("バックアップファイル一覧を更新しました: \(files.count)件")
            }
        }
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
        let entities = ["AnimalEntity", "PhysiologicalCycleEntity", "HealthRecordEntity"]
        
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
    
    // ファイルサイズのフォーマット
    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
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
