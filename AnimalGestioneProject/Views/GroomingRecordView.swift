import SwiftUI

struct GroomingRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    let animalId: UUID
    
    @State private var showingAddSheet = false
    @State private var selectedRecord: GroomingRecord?
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedFilter: GroomingFilterOption = .all
    
    enum GroomingFilterOption: String, CaseIterable, Identifiable {
        case all = "すべて"
        case upcoming = "予定"
        case past = "完了"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            List {
                // フィルターセクション
                Section {
                    Picker("表示", selection: $selectedFilter) {
                        ForEach(GroomingFilterOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 4)
                }
                
                // 次回予定セクション（フィルターが「すべて」または「予定」の場合のみ表示）
                if selectedFilter != .past, let nextGrooming = dataStore.getNextScheduledGrooming(animalId: animalId) {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.blue)
                                Text("次回予定")
                                    .font(.headline)
                            }
                            
                            HStack {
                                if let type = nextGrooming.groomingType {
                                    Text(type)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                } else {
                                    Text("トリミング")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                Text(formatDate(nextGrooming.scheduledDate))
                                    .font(.subheadline)
                            }
                            
                            // 残り日数の計算と表示
                            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: nextGrooming.scheduledDate).day ?? 0
                            HStack {
                                if daysRemaining < 0 {
                                    Text("期限が\(abs(daysRemaining))日過ぎています")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else if daysRemaining == 0 {
                                    Text("今日が予定日です")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                } else if daysRemaining <= 7 {
                                    Text("あと\(daysRemaining)日")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                } else {
                                    Text("あと\(daysRemaining)日")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("完了") {
                                    markAsCompleted(nextGrooming)
                                }
                                .buttonStyle(BorderedButtonStyle())
                                .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("次回予定")
                    }
                }
                
                // 記録リストセクション
                Section {
                    let records = filteredRecords()
                    
                    if records.isEmpty {
                        Text("トリミング記録はありません")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(records) { record in
                            Button(action: {
                                selectedRecord = record
                                showingEditSheet = true
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        if let type = record.groomingType {
                                            Text(type)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        } else {
                                            Text("トリミング")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(formatDate(record.date))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let nextDate = record.nextScheduledDate {
                                        HStack {
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                            Text("次回: \(formatDate(nextDate))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            // 残り日数
                                            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
                                            if daysRemaining < 0 {
                                                Text("(\(abs(daysRemaining))日超過)")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            } else if daysRemaining <= 7 {
                                                Text("(あと\(daysRemaining)日)")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                    
                                    if let notes = record.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete { indexSet in
                            let recordsToDelete = indexSet.map { filteredRecords()[$0] }
                            if let recordToDelete = recordsToDelete.first {
                                selectedRecord = recordToDelete
                                showingDeleteAlert = true
                            }
                        }
                    }
                } header: {
                    Text(selectedFilter == .upcoming ? "予定" : (selectedFilter == .past ? "完了" : "すべての記録"))
                }
            }
            .navigationTitle("トリミング記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddGroomingRecordView(animalId: animalId)
            }
            .sheet(isPresented: $showingEditSheet, onDismiss: {
                selectedRecord = nil
            }) {
                if let record = selectedRecord {
                    EditGroomingRecordView(record: record)
                }
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("記録を削除"),
                    message: Text("このトリミング記録を削除しますか？この操作は元に戻せません。"),
                    primaryButton: .destructive(Text("削除")) {
                        if let record = selectedRecord {
                            dataStore.deleteGroomingRecord(record)
                            selectedRecord = nil
                        }
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
        }
    }
    
    private func filteredRecords() -> [GroomingRecord] {
        let allRecords = dataStore.groomingRecordsForAnimal(id: animalId)
        
        switch selectedFilter {
        case .all:
            return allRecords
        case .upcoming:
            return allRecords.filter { record in
                guard let nextDate = record.nextScheduledDate else { return false }
                return nextDate >= Date()
            }
        case .past:
            return allRecords.filter { record in
                if let nextDate = record.nextScheduledDate {
                    return nextDate < Date()
                }
                return true
            }
        }
    }
    
    private func markAsCompleted(_ grooming: GroomingRecord) {
        // 完了としてマークする（現在の日付で新しい記録を作成）
        let newRecord = GroomingRecord(
            id: UUID(),
            animalId: animalId,
            date: Date(),
            groomingType: grooming.groomingType,
            nextScheduledDate: calculateNextDate(from: Date(), interval: grooming.interval ?? 30),
            interval: grooming.interval,
            notes: "前回の予定を完了としてマーク"
        )
        
        dataStore.addGroomingRecord(newRecord)
        
        // 元の予定を削除する場合もあり
        // dataStore.deleteGroomingRecord(grooming)
    }
    
    private func calculateNextDate(from date: Date, interval: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: interval, to: date) ?? date
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// トリミング記録追加画面
struct AddGroomingRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    let animalId: UUID
    
    @State private var groomingType = "フルコース"
    @State private var date = Date()
    @State private var scheduleNext = true
    @State private var interval = "30" // デフォルトは30日（1ヶ月）
    @State private var nextDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // 一般的なトリミングの種類
    private let groomingOptions = [
        "フルコース",
        "シャンプーのみ",
        "カットのみ",
        "爪切り",
        "歯磨き",
        "肛門腺絞り",
        "シャンプー＆ブロー",
        "その他"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("トリミング種類", selection: $groomingType) {
                        ForEach(groomingOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    if groomingType == "その他" {
                        TextField("種類を入力", text: $groomingType)
                    }
                    
                    DatePicker("実施日", selection: $date, displayedComponents: .date)
                }
                
                Section {
                    Toggle("次回を予定", isOn: $scheduleNext)
                    
                    if scheduleNext {
                        HStack {
                            Text("間隔")
                            TextField("30", text: $interval)
                                .keyboardType(.numberPad)
                                .onChange(of: interval) { _ in
                                    if let days = Int(interval) {
                                        nextDate = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
                                    }
                                }
                            Text("日")
                        }
                        
                        DatePicker("次回予定日", selection: $nextDate, displayedComponents: .date)
                            .onChange(of: nextDate) { _ in
                                let days = Calendar.current.dateComponents([.day], from: date, to: nextDate).day ?? 30
                                interval = "\(days)"
                            }
                    }
                }
                
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("トリミング記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRecord()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("エラー"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func saveRecord() {
        if groomingType.isEmpty {
            alertMessage = "トリミングの種類を入力してください"
            showingAlert = true
            return
        }
        
        var intervalValue: Int?
        if scheduleNext {
            guard let value = Int(interval), value > 0 else {
                alertMessage = "有効な日数を入力してください"
                showingAlert = true
                return
            }
            intervalValue = value
        }
        
        let newRecord = GroomingRecord(
            id: UUID(),
            animalId: animalId,
            date: date,
            groomingType: groomingType,
            nextScheduledDate: scheduleNext ? nextDate : nil,
            interval: intervalValue,
            notes: notes.isEmpty ? nil : notes
        )
        
        dataStore.addGroomingRecord(newRecord)
        presentationMode.wrappedValue.dismiss()
    }
}

// トリミング記録編集画面
struct EditGroomingRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    let record: GroomingRecord
    
    @State private var groomingType: String
    @State private var date: Date
    @State private var scheduleNext: Bool
    @State private var interval: String
    @State private var nextDate: Date
    @State private var notes: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // 一般的なトリミングの種類
    private let groomingOptions = [
        "フルコース",
        "シャンプーのみ",
        "カットのみ",
        "爪切り",
        "歯磨き",
        "肛門腺絞り",
        "シャンプー＆ブロー",
        "その他"
    ]
    
    init(record: GroomingRecord) {
        self.record = record
        
        _groomingType = State(initialValue: record.groomingType ?? "フルコース")
        _date = State(initialValue: record.date)
        _scheduleNext = State(initialValue: record.nextScheduledDate != nil)
        
        // 間隔の初期化
        if let interval = record.interval {
            _interval = State(initialValue: "\(interval)")
        } else {
            _interval = State(initialValue: "30")
        }
        
        // 次回日付の初期化
        if let nextDate = record.nextScheduledDate {
            _nextDate = State(initialValue: nextDate)
        } else {
            _nextDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 30, to: record.date) ?? record.date)
        }
        
        _notes = State(initialValue: record.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("トリミング種類", selection: $groomingType) {
                        ForEach(groomingOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                        
                        // 一般的なオプションにないカスタム値の場合
                        if !groomingOptions.contains(groomingType) && groomingType != "その他" {
                            Text(groomingType).tag(groomingType)
                        }
                    }
                    
                    if groomingType == "その他" || !groomingOptions.contains(groomingType) {
                        TextField("種類を入力", text: $groomingType)
                    }
                    
                    DatePicker("実施日", selection: $date, displayedComponents: .date)
                }
                
                Section {
                    Toggle("次回を予定", isOn: $scheduleNext)
                    
                    if scheduleNext {
                        HStack {
                            Text("間隔")
                            TextField("30", text: $interval)
                                .keyboardType(.numberPad)
                                .onChange(of: interval) { _ in
                                    if let days = Int(interval) {
                                        nextDate = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
                                    }
                                }
                            Text("日")
                        }
                        
                        DatePicker("次回予定日", selection: $nextDate, displayedComponents: .date)
                            .onChange(of: nextDate) { _ in
                                let days = Calendar.current.dateComponents([.day], from: date, to: nextDate).day ?? 30
                                interval = "\(days)"
                            }
                    }
                }
                
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("トリミング記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRecord()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("エラー"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func saveRecord() {
        if groomingType.isEmpty {
            alertMessage = "トリミングの種類を入力してください"
            showingAlert = true
            return
        }
        
        var intervalValue: Int?
        if scheduleNext {
            guard let value = Int(interval), value > 0 else {
                alertMessage = "有効な日数を入力してください"
                showingAlert = true
                return
            }
            intervalValue = value
        }
        
        var updatedRecord = record
        updatedRecord.groomingType = groomingType
        updatedRecord.date = date
        updatedRecord.nextScheduledDate = scheduleNext ? nextDate : nil
        updatedRecord.interval = intervalValue
        updatedRecord.notes = notes.isEmpty ? nil : notes
        
        dataStore.updateGroomingRecord(updatedRecord)
        presentationMode.wrappedValue.dismiss()
    }
}