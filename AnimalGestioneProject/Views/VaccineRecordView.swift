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
                
                // カスタムワクチンの場合はラベルを表示
                if !["混合ワクチン(DHPP)", "狂犬病", "ボルデテラ", "レプトスピラ", "ライム病", 
                    "猫江白血球減少症(FPV)", "猫カリシウイルス(FCV)", "猫ヘルペスウイルス(FHV)", 
                "猫白血病ウイルス(FeLV)", "猫免疫不全ウイルス(FIV)"].contains(nextVaccine.vaccineName) {
                        Text("カスタム")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                            
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
                                
                                if !nextVaccine.isCompleted {
                                    Button("完了") {
                                        markAsCompleted(nextVaccine)
                                    }
                                    .buttonStyle(BorderedButtonStyle())
                                    .font(.caption)
                                } else {
                                    Text("完了済み")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(5)
                                }
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
                                    
                                    // 通常のワクチンリストにない場合は「カスタム」と表示
                                    if !["混合ワクチン(DHPP)", "狂犬病", "ボルデテラ", "レプトスピラ", "ライム病", 
                                         "猫江白血球減少症(FPV)", "猫カリシウイルス(FCV)", "猫ヘルペスウイルス(FHV)", 
                                         "猫白血病ウイルス(FeLV)", "猫免疫不全ウイルス(FIV)"].contains(record.vaccineName) {
                                        Text("カスタム")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
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
                // 次回予定があり、未完了で、日付が今日以降
                guard let nextDate = record.nextScheduledDate else { return false }
                return !record.isCompleted && nextDate >= Date()
            }
        case .past:
            return allRecords.filter { record in
                // 完了済みまたは日付が過去
                if record.isCompleted {
                    return true
                }
                if let nextDate = record.nextScheduledDate {
                    return nextDate < Date()
                }
                return true
            }
        }
    }
    
    private func markAsCompleted(_ vaccine: VaccineRecord) {
        // 元の記録を完了済みに更新
        var updatedVaccine = vaccine
        updatedVaccine.isCompleted = true
        dataStore.updateVaccineRecord(updatedVaccine)
        
        // 次回予定がある場合は新しい記録を作成
        if let interval = vaccine.interval, interval > 0 {
            let newDate = calculateNextDate(from: Date(), interval: interval)
            let newRecord = VaccineRecord(
                id: UUID(),
                animalId: animalId,
                date: Date(),
                vaccineName: vaccine.vaccineName,
                nextScheduledDate: newDate,
                interval: interval,
                notes: "前回の予定から自動生成された次回予定",
                isCompleted: false
            )
            
            dataStore.addVaccineRecord(newRecord)
        }
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
    @State private var customVaccineName = ""
    @State private var vaccineType = ""
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
    
    // ページ表示時の初期化
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("ワクチン種類", selection: $vaccineType) {
                        ForEach(vaccineOptions, id: \.self) { vaccine in
                            Text(vaccine).tag(vaccine)
                        }
                    }
                    .onChange(of: vaccineType) { newValue in
                        if newValue == "その他" {
                            vaccineName = customVaccineName
                        } else {
                            vaccineName = newValue
                        }
                    }
                    
                    // その他を選択した場合はカスタム名を使用
                    if vaccineType == "その他" {
                        TextField("ワクチン名を入力", text: $customVaccineName)
                            .onChange(of: customVaccineName) { newValue in
                                vaccineName = newValue
                            }
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
            .onAppear {
                // 初期設定
                vaccineType = vaccineOptions.first ?? ""
                vaccineName = vaccineType
            }
        }
    }
    
    private func saveRecord() {
        // その他を選択した場合はカスタム名を使用
        var finalVaccineName = vaccineName
        if vaccineType == "その他" {
            finalVaccineName = customVaccineName.isEmpty ? "カスタムワクチン" : customVaccineName
            // カスタムワクチン名を更新
            vaccineName = finalVaccineName
        }
        
        if finalVaccineName.isEmpty {
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
        
        // メモが空であれば、その他の場合はカスタム名をメモに含める
        var recordNotes = notes
        
        let newRecord = VaccineRecord(
            id: UUID(),
            animalId: animalId,
            date: date,
            vaccineName: finalVaccineName,
            nextScheduledDate: scheduleNextVaccine ? nextDate : nil,
            interval: intervalValue,
            notes: recordNotes.isEmpty ? nil : recordNotes
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
    @State private var customVaccineName: String
    @State private var vaccineType: String
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
        
        // ワクチンタイプとカスタム名の初期化
        if let existingType = ["混合ワクチン(DHPP)", "狂犬病", "ボルデテラ", "レプトスピラ", "ライム病", 
                           "猫汎白血球減少症(FPV)", "猫カリシウイルス(FCV)", "猫ヘルペスウイルス(FHV)", 
                           "猫白血病ウイルス(FeLV)", "猫免疫不全ウイルス(FIV)"].first(where: { $0 == record.vaccineName }) {
            _vaccineType = State(initialValue: existingType)
            _customVaccineName = State(initialValue: "")
        } else {
            _vaccineType = State(initialValue: "その他")
            _customVaccineName = State(initialValue: record.vaccineName)
        }
        
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
                    Picker("ワクチン種類", selection: $vaccineType) {
                        ForEach(vaccineOptions, id: \.self) { vaccine in
                            Text(vaccine).tag(vaccine)
                        }
                    }
                    .onChange(of: vaccineType) { newValue in
                        if newValue == "その他" {
                            // カスタム入力フィールド用あ
                        } else {
                            vaccineName = newValue
                        }
                    }
                    
                    if vaccineType == "その他" {
                        TextField("ワクチン名を入力", text: $customVaccineName)
                            .onChange(of: customVaccineName) { newValue in
                                vaccineName = newValue
                            }
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
        // その他を選択した場合はカスタム名を使用
        var finalVaccineName = vaccineName
        if vaccineType == "その他" {
            finalVaccineName = customVaccineName.isEmpty ? "カスタムワクチン" : customVaccineName
            // カスタムワクチン名を更新
            vaccineName = finalVaccineName
        }
        
        if finalVaccineName.isEmpty {
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
        updatedRecord.vaccineName = finalVaccineName
        updatedRecord.date = date
        updatedRecord.nextScheduledDate = scheduleNextVaccine ? nextDate : nil
        updatedRecord.interval = intervalValue
        updatedRecord.notes = notes.isEmpty ? nil : notes
        
        dataStore.updateVaccineRecord(updatedRecord)
        presentationMode.wrappedValue.dismiss()
    }
}