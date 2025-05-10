import SwiftUI

struct AnimalDetailView: View {
    @EnvironmentObject var dataStore: CoreDataStore
    @ObservedObject private var adManager = AdManager.shared
    @State private var isShowingPremiumHealthCheck = false
    @State private var animal: Animal
    @State private var isEditing = false
    @State private var showingPhysiologicalCycle = false
    @State private var showingHealthRecord = false
    @State private var showingWeightRecord = false
    @State private var showingVaccineRecord = false
    @State private var showingGroomingRecord = false
    @State private var showingColorPicker = false
    @State private var selectedColor: Color
    
    // タブアイコンの設定を取得
    @AppStorage("animalIcon") private var animalIcon = "pawprint"
    
    init(animal: Animal) {
        _animal = State(initialValue: animal)
        _selectedColor = State(initialValue: animal.color)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー
                HStack {
                    Spacer()
                    if let imageUrl = animal.imageUrl, let uiImage = loadImage(from: imageUrl) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: animalIcon + ".circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                
                // 基本情報
                GroupBox(label: Label("基本情報", systemImage: "info.circle")) {
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(label: "名前", value: animal.name)
                        InfoRow(label: "種類", value: animal.species)
                        if let breed = animal.breed {
                            InfoRow(label: "品種", value: breed)
                        }
                        InfoRow(label: "性別", value: animal.gender.rawValue)
                        if let birthDate = animal.birthDate {
                            InfoRow(label: "誕生日", value: formatDate(birthDate))
                            InfoRow(label: "年齢", value: calculateAge(from: birthDate))
                        }
                        
                        // 色選択
                        HStack {
                            Text("テーマ色")
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                                
                            Button(action: {
                                showingColorPicker = true
                            }) {
                                Circle()
                                    .fill(animal.color)
                                    .frame(width: 24, height: 24)
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                    }
                    .padding(.vertical)
                }
                
                // 健康記録セクション
                GroupBox(label: Label("健康記録", systemImage: "heart")) {
                    VStack(alignment: .leading, spacing: 10) {
                        let records = dataStore.healthRecordsForAnimal(id: animal.id)
                        
                        if records.isEmpty {
                            Text("記録なし")
                                .foregroundColor(.secondary)
                                .padding(.vertical)
                        } else {
                            ForEach(records.prefix(3)) { record in
                                HealthRecordRow(record: record)
                            }
                            
                            if records.count > 3 {
                                Button("すべて表示") {
                                    showingHealthRecord = true
                                }
                                .padding(.top)
                            }
                        }
                        
                        HStack {
                            Button(action: {
                                print("健康記録ボタンがタップされました - 動物ID: \(animal.id)")
                                showingHealthRecord = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                    Text("健康記録を管理")
                                }
                                .padding(.vertical, 4)
                            }
                            
                            Spacer()
                            
                            // プレミアム健康チェックボタン
                            Button(action: {
                                isShowingPremiumHealthCheck = true
                            }) {
                                HStack {
                                    Image(systemName: "crown")
                                        .foregroundColor(.yellow)
                                    Text("高度健康分析")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.top)
                    }
                    .padding(.vertical)
                }
                
                // トリミング記録セクション
                GroupBox(label: Label("トリミング記録", systemImage: "scissors")) {
                    VStack(alignment: .leading, spacing: 10) {
                        let groomingRecords = dataStore.groomingRecordsForAnimal(id: animal.id)
                        
                        if groomingRecords.isEmpty {
                            Text("記録なし")
                                .foregroundColor(.secondary)
                                .padding(.vertical)
                        } else {
                            ForEach(groomingRecords.prefix(3)) { record in
                                GroomingRecordRow(record: record)
                            }
                            
                            if groomingRecords.count > 3 {
                                Button("すべて表示") {
                                    showingGroomingRecord = true
                                }
                                .padding(.top)
                            }
                        }
                        
                        if let nextGrooming = dataStore.getNextScheduledGrooming(animalId: animal.id) {
                            Divider()
                            Text("次回予定: \(formatDate(nextGrooming.scheduledDate))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            showingGroomingRecord = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                Text("トリミング記録を管理")
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(.top)
                    }
                    .padding(.vertical)
                }
                
                // 生理周期セクション
                GroupBox(label: Label("生理周期", systemImage: "calendar")) {
                    VStack(alignment: .leading, spacing: 10) {
                        let cycles = dataStore.cyclesForAnimal(id: animal.id)
                        
                        if cycles.isEmpty {
                            Text("記録なし")
                                .foregroundColor(.secondary)
                                .padding(.vertical)
                        } else {
                            ForEach(cycles.prefix(3)) { cycle in
                                PhysiologicalCycleRow(cycle: cycle)
                            }
                            
                            if cycles.count > 3 {
                                Button("すべて表示") {
                                    showingPhysiologicalCycle = true
                                }
                                .padding(.top)
                            }
                        }
                        
                        if let nextPrediction = dataStore.predictNextCycle(animalId: animal.id) {
                            Divider()
                            Text("次回予測: \(formatDate(nextPrediction))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            showingPhysiologicalCycle = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                Text("生理周期を管理")
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(.top)
                    }
                    .padding(.vertical)
                }
                
                // ワクチン記録セクション
                GroupBox(label: Label("ワクチン記録", systemImage: "syringe")) {
                    VStack(alignment: .leading, spacing: 10) {
                        let vaccineRecords = dataStore.vaccineRecordsForAnimal(id: animal.id)
                        
                        if vaccineRecords.isEmpty {
                            Text("記録なし")
                                .foregroundColor(.secondary)
                                .padding(.vertical)
                        } else {
                            ForEach(vaccineRecords.prefix(3)) { record in
                                VaccineRecordRow(record: record)
                            }
                            
                            if vaccineRecords.count > 3 {
                                Button("すべて表示") {
                                    showingVaccineRecord = true
                                }
                                .padding(.top)
                            }
                        }
                        
                        if let nextVaccine = dataStore.getNextScheduledVaccine(animalId: animal.id) {
                            Divider()
                            Text("次回予定: \(formatDate(nextVaccine.scheduledDate))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            showingVaccineRecord = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                Text("ワクチン記録を管理")
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(.top)
                    }
                    .padding(.vertical)
                }
            }
            .padding()
        }
        .navigationTitle(animal.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isEditing = true
                }) {
                    Text("編集")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditAnimalView(animal: animal) { updatedAnimal in
                animal = updatedAnimal
                dataStore.updateAnimal(updatedAnimal)
            }
        }
        .sheet(isPresented: $showingPhysiologicalCycle) {
            PhysiologicalCycleView(animalId: animal.id)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showingHealthRecord) {
            NavigationView {
                AnimalGestioneProject.HealthRecordView(animalId: animal.id, isEmbedded: true)
                    .environmentObject(dataStore)
                    .navigationBarItems(leading: Button("閉じる") {
                        self.showingHealthRecord = false
                    })
            }
        }
        .sheet(isPresented: $showingWeightRecord) {
            WeightRecordView(animalId: animal.id)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showingVaccineRecord) {
            VaccineRecordView(animalId: animal.id)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showingGroomingRecord) {
            GroomingRecordView(animalId: animal.id)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $isShowingPremiumHealthCheck) {
            PremiumHealthCheckView(animalId: animal.id)
                .environmentObject(dataStore)
        }
        .sheet(isPresented: $showingColorPicker) {
            VStack {
                Text("テーマ色を選択")
                    .font(.headline)
                    .padding()
                
                ColorPicker("色を選択", selection: $selectedColor)
                    .padding()
                
                Button("適用") {
                    var updatedAnimal = animal
                    updatedAnimal.color = selectedColor
                    dataStore.updateAnimalColor(id: animal.id, color: selectedColor)
                    animal = updatedAnimal
                    showingColorPicker = false
                    
                    // 色変更の通知を送信
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AnimalColorChanged"),
                        object: animal.id
                    )
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func loadImage(from url: URL) -> UIImage? {
        // 実際のアプリではキャッシングやエラーハンドリングを追加
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func calculateAge(from birthDate: Date) -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year, .month], from: birthDate, to: Date())
        
        guard let years = ageComponents.year, let months = ageComponents.month else {
            return "不明"
        }
        
        if years > 0 {
            return "\(years)歳\(months)ヶ月"
        } else {
            return "\(months)ヶ月"
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
            
            Spacer()
        }
    }
}

struct PhysiologicalCycleRow: View {
    let cycle: PhysiologicalCycle
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(formatDate(cycle.startDate))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let endDate = cycle.endDate {
                    Text("〜 \(formatDate(endDate))")
                        .font(.subheadline)
                }
                
                Spacer()
                
                Text(cycle.intensity.description)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(intensityColor(cycle.intensity).opacity(0.2))
                    .foregroundColor(intensityColor(cycle.intensity))
                    .cornerRadius(4)
            }
            
            if let notes = cycle.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func intensityColor(_ intensity: PhysiologicalCycle.Intensity) -> Color {
        switch intensity {
        case .light:
            return .green
        case .medium:
            return .orange
        case .heavy:
            return .red
        }
    }
}

struct HealthRecordRow: View {
    let record: HealthRecord
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(formatDate(record.date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let weight = record.weight {
                    Text("\(String(format: "%.1f", weight)) kg")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                if let temperature = record.temperature {
                    Text("\(String(format: "%.1f", temperature)) °C")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
            
            HStack {
                Text("食欲: \(record.appetite.description)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("活動量: \(record.activityLevel.description)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct VaccineRecordRow: View {
    let record: VaccineRecord
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(formatDate(record.date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(record.vaccineName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
            
            if let nextDate = record.nextScheduledDate {
                Text("次回予定: \(formatDate(nextDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct GroomingRecordRow: View {
    let record: GroomingRecord
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(formatDate(record.date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let groomingType = record.groomingType {
                    Text(groomingType)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
            }
            
            if let nextDate = record.nextScheduledDate {
                Text("次回予定: \(formatDate(nextDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}