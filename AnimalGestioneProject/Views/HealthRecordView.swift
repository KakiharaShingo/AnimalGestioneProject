import SwiftUI

struct HealthRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    @State private var showingAddRecord = false
    @State private var selectedRecord: HealthRecord?
    @State private var animal: Animal? = nil
    
    // パラメータ
    let animalId: UUID
    var isEmbedded: Bool
    
    // イニシャライザ
    init(animalId: UUID, isEmbedded: Bool = false) {
        self.animalId = animalId
        self.isEmbedded = isEmbedded
    }
    
    var body: some View {
        Group {
            if isEmbedded {
                // 埋め込み表示の場合はナビゲーションビューを付けない
                healthRecordContent
            } else {
                // 通常の表示の場合はナビゲーションビューを付ける
                NavigationView {
                    healthRecordContent
                }
            }
        }
        .onAppear {
            // ビュー表示時に動物情報を取得
            loadAnimal()
        }
    }
    
    // 動物情報を取得
    private func loadAnimal() {
        print("動物ID \(animalId) の情報を読み込み中...")
        if let foundAnimal = dataStore.animals.first(where: { $0.id == animalId }) {
            print("動物情報を読み込み成功: \(foundAnimal.name)")
            self.animal = foundAnimal
        } else {
            print("警告: 動物ID \(animalId) を持つ動物が見つかりません")
            // 利用可能な動物一覧を出力
            let availableAnimals = dataStore.animals.map { "\($0.name) (ID: \($0.id))" }.joined(separator: ", ")
            print("利用可能な動物: \(availableAnimals)")
        }
    }
    
    private var healthRecordContent: some View {
        Group {
            if let animal = animal {
                List {
                    // 動物情報ヘッダー
                    Section {
                        HStack {
                            if let imageUrl = animal.imageUrl, let uiImage = loadImage(from: imageUrl) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "pawprint.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(animal.color)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(animal.name)
                                    .font(.headline)
                                
                                Text("\(animal.species) (\(animal.gender.rawValue))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 健康記録のリスト
                    Section(header: Text("健康記録")) {
                        let records = dataStore.healthRecordsForAnimal(id: animalId)
                        
                        if records.isEmpty {
                            Text("記録はありません")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(records) { record in
                                HealthRecordRow(record: record)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedRecord = record
                                    }
                            }
                            .onDelete(perform: deleteRecords)
                        }
                    }
                }
                .navigationTitle("健康記録")
                .toolbar {
                    // 埋め込みモードの場合は閉じるボタンを表示しない
                    if !isEmbedded {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("閉じる") {
                                // モーダルを確実に閉じる
                                DispatchQueue.main.async {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddRecord = true
                        }) {
                            Label("追加", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddRecord) {
                    AddHealthRecordView(animalId: animalId)
                }
                .sheet(item: $selectedRecord) { record in
                    EditHealthRecordView(record: record) { updatedRecord in
                        dataStore.updateHealthRecord(updatedRecord)
                    }
                }
            } else {
                // 動物が見つからない場合のフォールバック
                VStack {
                    Text("ペットの情報を読み込めませんでした")
                        .font(.headline)
                        .padding()
                    
                    Button("閉じる") {
                        DispatchQueue.main.async {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding()
                }
                .navigationTitle("エラー")
            }
        }
    }
    
    private func deleteRecords(at offsets: IndexSet) {
        let records = dataStore.healthRecordsForAnimal(id: animalId)
        offsets.forEach { index in
            let record = records[index]
            dataStore.deleteHealthRecord(id: record.id)
        }
    }
    
    private func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

struct AddHealthRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    
    @State private var date = Date()
    @State private var weight = ""
    @State private var temperature = ""
    @State private var appetite = HealthRecord.Appetite.normal
    @State private var activityLevel = HealthRecord.ActivityLevel.normal
    @State private var notes = ""
    
    let animalId: UUID
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("日付", selection: $date, displayedComponents: .date)
                
                Section(header: Text("体重")) {
                    TextField("体重 (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("体温")) {
                    TextField("体温 (°C)", text: $temperature)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("食欲")) {
                    Picker("食欲", selection: $appetite) {
                        Text("食欲不振").tag(HealthRecord.Appetite.poor)
                        Text("普通").tag(HealthRecord.Appetite.normal)
                        Text("食欲旺盛").tag(HealthRecord.Appetite.good)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("活動量")) {
                    Picker("活動量", selection: $activityLevel) {
                        Text("低活動").tag(HealthRecord.ActivityLevel.low)
                        Text("普通").tag(HealthRecord.ActivityLevel.normal)
                        Text("活発").tag(HealthRecord.ActivityLevel.high)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("健康記録を追加")
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
        }
    }
    
    private func saveRecord() {
        let record = HealthRecord(
            animalId: animalId,
            date: date,
            weight: Double(weight),
            temperature: Double(temperature),
            appetite: appetite,
            activityLevel: activityLevel,
            notes: notes.isEmpty ? nil : notes
        )
        
        dataStore.addHealthRecord(record)
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditHealthRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var date: Date
    @State private var weight: String
    @State private var temperature: String
    @State private var appetite: HealthRecord.Appetite
    @State private var activityLevel: HealthRecord.ActivityLevel
    @State private var notes: String
    
    private var originalRecord: HealthRecord
    private var onSave: (HealthRecord) -> Void
    
    init(record: HealthRecord, onSave: @escaping (HealthRecord) -> Void) {
        self.originalRecord = record
        self.onSave = onSave
        
        _date = State(initialValue: record.date)
        _weight = State(initialValue: record.weight != nil ? String(format: "%.1f", record.weight!) : "")
        _temperature = State(initialValue: record.temperature != nil ? String(format: "%.1f", record.temperature!) : "")
        _appetite = State(initialValue: record.appetite)
        _activityLevel = State(initialValue: record.activityLevel)
        _notes = State(initialValue: record.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("日付", selection: $date, displayedComponents: .date)
                
                Section(header: Text("体重")) {
                    TextField("体重 (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("体温")) {
                    TextField("体温 (°C)", text: $temperature)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("食欲")) {
                    Picker("食欲", selection: $appetite) {
                        Text("食欲不振").tag(HealthRecord.Appetite.poor)
                        Text("普通").tag(HealthRecord.Appetite.normal)
                        Text("食欲旺盛").tag(HealthRecord.Appetite.good)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("活動量")) {
                    Picker("活動量", selection: $activityLevel) {
                        Text("低活動").tag(HealthRecord.ActivityLevel.low)
                        Text("普通").tag(HealthRecord.ActivityLevel.normal)
                        Text("活発").tag(HealthRecord.ActivityLevel.high)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("健康記録を編集")
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
        }
    }
    
    private func saveRecord() {
        var updatedRecord = originalRecord
        updatedRecord.date = date
        updatedRecord.weight = Double(weight)
        updatedRecord.temperature = Double(temperature)
        updatedRecord.appetite = appetite
        updatedRecord.activityLevel = activityLevel
        updatedRecord.notes = notes.isEmpty ? nil : notes
        
        onSave(updatedRecord)
        presentationMode.wrappedValue.dismiss()
    }
}