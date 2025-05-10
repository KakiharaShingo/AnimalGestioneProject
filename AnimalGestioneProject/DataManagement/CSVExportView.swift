import SwiftUI
import UIKit

struct CSVExportView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedCSVType = 0
    @State private var csvFiles: [URL] = []
    @State private var showingShareSheet = false
    @State private var selectedFile: URL?
    @State private var showingDeleteAlert = false
    @State private var isExporting = false
    @State private var exportSuccess = false
    @State private var exportError: String?
    
    private let csvExportManager = CSVDataExportManager.shared
    
    // CSV出力タイプの選択肢
    private let csvTypes = ["動物データ", "ワクチン記録", "健康診断記録", "体重記録", "すべてのデータ"]
    
    var body: some View {
        NavigationView {
            List {
                // CSVエクスポートセクション
                Section(header: Text("CSVエクスポート")) {
                    Picker("エクスポートするデータ", selection: $selectedCSVType) {
                        ForEach(0..<csvTypes.count, id: \.self) { index in
                            Text(csvTypes[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 8)
                    
                    Button(action: {
                        exportSelectedCSV()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("CSVとしてエクスポート")
                        }
                    }
                    .disabled(isExporting)
                    
                    if isExporting {
                        HStack {
                            Text("エクスポート中...")
                            Spacer()
                            ProgressView()
                        }
                    }
                    
                    if exportSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("エクスポート完了")
                                .foregroundColor(.green)
                        }
                    }
                    
                    if let error = exportError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // 既存のCSVファイル一覧
                Section(header: Text("エクスポート済みCSVファイル")) {
                    ForEach(csvFiles, id: \.absoluteString) { url in
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
                                selectedFile = url
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.green)
                            }
                            
                            Button(action: {
                                selectedFile = url
                                showingDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if csvFiles.isEmpty {
                        Text("エクスポート済みのCSVファイルがありません")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
                
                // CSVインポートについての説明
                Section(header: Text("CSVインポートについて"), footer: Text("CSVファイルの形式については、エクスポートしたファイルを参考にしてください。")) {
                    Text("CSVファイルはExcelなどの表計算ソフトで開くことができ、データの閲覧や編集に便利です。エクスポートしたCSVファイルはスプレッドシートなどでバックアップとして保存できます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("CSVエクスポート")
            .navigationBarItems(leading: Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                refreshCSVFiles()
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("ファイルの削除"),
                    message: Text("このCSVファイルを削除しますか？"),
                    primaryButton: .destructive(Text("削除")) {
                        if let url = selectedFile {
                            deleteCSVFile(url)
                        }
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
            .background(
                EmptyView().sheet(isPresented: $showingShareSheet) {
                    if let url = selectedFile {
                        ShareSheet(activityItems: [url])
                    }
                }
            )
        }
    }
    
    // CSVファイル一覧を更新
    private func refreshCSVFiles() {
        csvFiles = csvExportManager.getAvailableCSVFiles()
    }
    
    // 選択したタイプのCSVをエクスポート
    private func exportSelectedCSV() {
        isExporting = true
        exportSuccess = false
        exportError = nil
        
        var exportedURL: URL?
        
        switch selectedCSVType {
        case 0: // 動物データ
            exportedURL = csvExportManager.exportAnimalsToCSV()
        case 1: // ワクチン記録
            exportedURL = csvExportManager.exportVaccineRecordsToCSV()
        case 2: // 健康診断記録
            exportedURL = csvExportManager.exportCheckupRecordsToCSV()
        case 3: // 体重記録
            exportedURL = csvExportManager.exportWeightRecordsToCSV()
        case 4: // すべてのデータ
            exportedURL = csvExportManager.exportAllDataToCSVArchive()
        default:
            exportedURL = nil
        }
        
        if let url = exportedURL {
            exportSuccess = true
            
            // 成功後、ファイル一覧を更新
            refreshCSVFiles()
            
            // エクスポートしたファイルを共有
            selectedFile = url
            
            // 少し遅延して共有シートを表示（UIの更新が完了するのを待つ）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingShareSheet = true
            }
        } else {
            exportError = "エクスポートに失敗しました"
        }
        
        isExporting = false
    }
    
    // CSVファイルを削除
    private func deleteCSVFile(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            refreshCSVFiles()
        } catch {
            print("CSVファイル削除エラー: \(error.localizedDescription)")
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

// プレビュー
struct CSVExportView_Previews: PreviewProvider {
    static var previews: some View {
        CSVExportView()
    }
}
