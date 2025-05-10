import SwiftUI

struct VaccineRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    let animalId: UUID
    
    @State private var showingAddSheet = false
    @State private var selectedRecord: VaccineRecord?
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedFilter: VaccineFilterOption = .all
    
    enum VaccineFilterOption: String, CaseIterable, Identifiable {
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
                        ForEach(VaccineFilterOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 4)
                }
                
                // 次回予定セクション（フィルターが「すべて」または「予定」の場合のみ表示）
                if selectedFilter != .past, let nextVaccine = dataStore.getNextScheduledVaccine(animalId: animalId) {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.blue)
                                Text("次回予定")
                                    .font(.headline)
                            }
                            
                            HStack {
                                Text(nextVaccine.vaccineName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text(formatDate(nextVaccine.scheduledDate))
                                    .font(.subheadline)
                            }
                            
                            // 残り日数の計算と表示
                            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: nextVaccine.scheduledDate).day ?? 0
                            HStack {
                                if daysRemaining < 0 {
                                    Text("期限が\(abs(daysRemaining))日過ぎています")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else if daysRemaining == 0 {
                                    Text("今日が接種日です")
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
                                    markAsCompleted(nextVaccine)
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
                        Text("ワクチン記録はありません")
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
                                        Text(record.vaccineName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
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
            .navigationTitle("ワクチン記録")
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
                AddVaccineRecordView(animalId: animalId)
            }
            .sheet(isPresented: $showingEditSheet, onDismiss: {
                selectedRecord = nil
            }) {
                if let record = selectedRecord {
                    EditVaccineRecordView(record: record)
                }
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("記録を削除"),
                    message: Text("このワクチン記録を削除しますか？この操作は元に戻せません。"),
                    primaryButton: .destructive(Text("削除")) {
                        if let record = selectedRecord {
                            dataStore.deleteVaccineRecord(record)
                            selectedRecord = nil
                        }
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
        }
    }
    
    private func filteredRecords() -> [VaccineRecord] {
        let allRecords = dataStore.vaccineRecordsForAnimal(id: animalId)
        
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
    
    private func markAsCompleted(_ vaccine: VaccineRecord) {
        // 完了としてマークする（現在の日付で新しい記録を作成）
        let newRecord = VaccineRecord(
            id: UUID(),
            animalId: animalId,
            date: Date(),
            vaccineName: vaccine.vaccineName,
            nextScheduledDate: calculateNextDate(from: Date(), interval: vaccine.interval ?? 365),
            interval: vaccine.interval,
            notes: "前回の予定を完了としてマーク"
        )
        
        dataStore.addVaccineRecord(newRecord)
        
        // 元の予定を削除する場合もあり
        // dataStore.deleteVaccineRecord(vaccine)
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

// ワクチン記録追加画面
struct AddVaccineRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    let animalId: UUID
    
    @State private var vaccineName = ""
    @State private var date = Date()
    @State private var scheduleNextVaccine = true
    @State private var interval = "365" // デフォルトは1年
    @State private var nextDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // 一般的なワクチンの選択肢
    private let vaccineOptions = [
        "混合ワクチン(DHPP)",
        "狂犬病",
        "ボルデテラ",
        "レプトスピラ",
        "ライム病",
        "猫汎白血球減少症(FPV)",
        "猫カリシウイルス(FCV)",
        "猫ヘルペスウイルス(FHV)",
        "猫白血病ウイルス(FeLV)",
        "猫免疫不全ウイルス(FIV)",
        "その他"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("ワクチン種類", selection: $vaccineName) {
                        ForEach(vaccineOptions, id: \.self) { vaccine in
                            Text(vaccine).tag(vaccine)
                        }
                    }
                    
                    if vaccineName == "その他" {
                        TextField("ワクチン名を入力", text: $vaccineName)
                    }
                    
                    DatePicker("接種日", selection: $date, displayedComponents: .date)
                }
                
                Section {
                    Toggle("次回接種を予定", isOn: $scheduleNextVaccine)
                    
                    if scheduleNextVaccine {
                        HStack {
                            Text("間隔")
                            TextField("365", text: $interval)
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
                                let days = Calendar.current.dateComponents([.day], from: date, to: nextDate).day ?? 365
                                interval = "\(days)"
                            }
                    }
                }
                
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("ワクチン記録を追加")
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
        if vaccineName.isEmpty {
            alertMessage = "ワクチン名を入力してください"
            showingAlert = true
            return
        }
        
        var intervalValue: Int?
        if scheduleNextVaccine {
            guard let value = Int(interval), value > 0 else {
                alertMessage = "有効な日数を入力してください"
                showingAlert = true
                return
            }
            intervalValue = value
        }
        
        let newRecord = VaccineRecord(
            id: UUID(),
            animalId: animalId,
            date: date,
            vaccineName: vaccineName,
            nextScheduledDate: scheduleNextVaccine ? nextDate : nil,
            interval: intervalValue,
            notes: notes.isEmpty ? nil : notes
        )
        
        dataStore.addVaccineRecord(newRecord)
        presentationMode.wrappedValue.dismiss()
    }
}

// ワクチン記録編集画面
struct EditVaccineRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    let record: VaccineRecord
    
    @State private var vaccineName: String
    @State private var date: Date
    @State private var scheduleNextVaccine: Bool
    @State private var interval: String
    @State private var nextDate: Date
    @State private var notes: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // 一般的なワクチンの選択肢
    private let vaccineOptions = [
        "混合ワクチン(DHPP)",
        "狂犬病",
        "ボルデテラ",
        "レプトスピラ",
        "ライム病",
        "猫汎白血球減少症(FPV)",
        "猫カリシウイルス(FCV)",
        "猫ヘルペスウイルス(FHV)",
        "猫白血病ウイルス(FeLV)",
        "猫免疫不全ウイルス(FIV)",
        "その他"
    ]
    
    init(record: VaccineRecord) {
        self.record = record
        
        _vaccineName = State(initialValue: record.vaccineName)
        _date = State(initialValue: record.date)
        _scheduleNextVaccine = State(initialValue: record.nextScheduledDate != nil)
        
        // 間隔の初期化
        if let interval = record.interval {
            _interval = State(initialValue: "\(interval)")
        } else {
            _interval = State(initialValue: "365")
        }
        
        // 次回日付の初期化
        if let nextDate = record.nextScheduledDate {
            _nextDate = State(initialValue: nextDate)
        } else {
            _nextDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 365, to: record.date) ?? record.date)
        }
        
        _notes = State(initialValue: record.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("ワクチン種類", selection: $vaccineName) {
                        ForEach(vaccineOptions, id: \.self) { vaccine in
                            Text(vaccine).tag(vaccine)
                        }
                        
                        // 一般的なオプションにないカスタム値の場合
                        if !vaccineOptions.contains(vaccineName) && vaccineName != "その他" {
                            Text(vaccineName).tag(vaccineName)
                        }
                    }
                    
                    if vaccineName == "その他" || !vaccineOptions.contains(vaccineName) {
                        TextField("ワクチン名を入力", text: $vaccineName)
                    }
                    
                    DatePicker("接種日", selection: $date, displayedComponents: .date)
                }
                
                Section {
                    Toggle("次回接種を予定", isOn: $scheduleNextVaccine)
                    
                    if scheduleNextVaccine {
                        HStack {
                            Text("間隔")
                            TextField("365", text: $interval)
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
                                let days = Calendar.current.dateComponents([.day], from: date, to: nextDate).day ?? 365
                                interval = "\(days)"
                            }
                    }
                }
                
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("ワクチン記録を編集")
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
        if vaccineName.isEmpty {
            alertMessage = "ワクチン名を入力してください"
            showingAlert = true
            return
        }
        
        var intervalValue: Int?
        if scheduleNextVaccine {
            guard let value = Int(interval), value > 0 else {
                alertMessage = "有効な日数を入力してください"
                showingAlert = true
                return
            }
            intervalValue = value
        }
        
        var updatedRecord = record
        updatedRecord.vaccineName = vaccineName
        updatedRecord.date = date
        updatedRecord.nextScheduledDate = scheduleNextVaccine ? nextDate : nil
        updatedRecord.interval = intervalValue
        updatedRecord.notes = notes.isEmpty ? nil : notes
        
        dataStore.updateVaccineRecord(updatedRecord)
        presentationMode.wrappedValue.dismiss()
    }
}