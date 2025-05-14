import SwiftUI

struct EnhancedHomeView: View {
    @EnvironmentObject var dataStore: CoreDataStore
    @Binding var selectedDate: Date
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 検索バー
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    // 今日の予定セクション
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("今日の予定")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                selectedDate = Date()
                                
                                // カレンダータブに切り替える
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("SwitchToTab"),
                                    object: EnhancedContentView.Tab.calendar
                                )
                                print("カレンダータブへ切り替え通知送信")
                            }) {
                                Text("すべて表示")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        let todaysEvents = dataStore.scheduledEventsOn(date: Date())
                        
                        if todaysEvents.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar.badge.clock")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(Color.gray.opacity(0.5))
                                    
                                    Text("今日の予定はありません")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(todaysEvents) { event in
                                        EnhancedEventCard(event: event)
                                            .frame(width: 220)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                            }
                        }
                    }
                    
                    // マイペットセクション
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("マイペット")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                // ペットタブに切り替える
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("SwitchToTab"),
                                    object: EnhancedContentView.Tab.pets
                                )
                                print("ペットタブへ切り替え通知送信")
                            }) {
                                Text("すべて表示")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        let filteredAnimals = searchText.isEmpty ? dataStore.animals : dataStore.animals.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.species.localizedCaseInsensitiveContains(searchText) }
                        
                        if filteredAnimals.isEmpty {
                            EmptyAnimalView()
                                .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(filteredAnimals) { animal in
                                        Button(action: {
                                            // ペットタブに切り替え
                                            NotificationCenter.default.post(
                                                name: NSNotification.Name("SwitchToTab"),
                                                object: EnhancedContentView.Tab.pets
                                            )
                                            print("ペットタブへ切り替え通知送信")
                                            
                                            // 少し遅延させてから詳細画面を開く
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                NotificationCenter.default.post(
                                                    name: NSNotification.Name("OpenAnimalDetail"),
                                                    object: animal.id
                                                )
                                                print("動物詳細画面通知送信: \(animal.id)")
                                            }
                                        }) {
                                            AnimalCard(animal: animal)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                            }
                        }
                    }
                    
                    // 近日の生理周期予測セクション
                    VStack(alignment: .leading, spacing: 10) {
                        Text("近日の生理周期予測")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        ForEach(upcomingCyclePredictions, id: \.animal.id) { prediction in
                            Button(action: {
                                // 動物詳細タブに切り替え
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("SwitchToTab"),
                                    object: EnhancedContentView.Tab.pets
                                )
                                print("ペットタブへ切り替え通知送信")
                                // 詳細画面を開くためのタイマー
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("OpenAnimalDetail"),
                                        object: prediction.animal.id
                                    )
                                    print("動物詳細画面通知送信: \(prediction.animal.id)")
                                }
                            }) {
                                PredictionCard(animal: prediction.animal, date: prediction.date)
                            }
                        }
                        
                        if upcomingCyclePredictions.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(Color.gray.opacity(0.5))
                                    
                                    Text("予測可能な生理周期はありません")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                    
                    // 最近の健康記録セクション
                    VStack(alignment: .leading, spacing: 10) {
                        Text("最近の健康記録")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        if let record = dataStore.healthRecords.first, let animal = dataStore.animals.first(where: { $0.id == record.animalId }) {
                            Button(action: {
                                // 動物情報が存在するか確認
                                if let animalWithId = dataStore.animals.first(where: { $0.id == record.animalId }) {
                                    print("健康記録ボタン押下 - ペットタブに切り替え中...")
                                    
                                    // まずタブの切り替えを行う
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("SwitchToTab"),
                                        object: EnhancedContentView.Tab.pets
                                    )
                                    print("ペットタブへ切り替え通知送信")
                                    
                                    // OpenAnimalDetailを送信してペットの詳細表示に遷移
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        print("動物詳細画面に遷移中: \(animalWithId.name)")
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("OpenAnimalDetail"),
                                            object: record.animalId
                                        )
                                    }
                                } else {
                                    print("エラー: 健康記録\(record.id)の動物ID \(record.animalId) が見つかりません")
                                }
                            }) {
                                LatestHealthCard(record: record)
                            }
                        } else {
                            HStack {
                                Spacer()
                                VStack(spacing: 10) {
                                    Image(systemName: "heart.text.square")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(Color.gray.opacity(0.5))
                                    
                                    Text("健康記録がありません")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("ホーム")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 通知センターを開く
                        // 通知の実際の処理はここに記述
                    }) {
                        Image(systemName: "bell")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var upcomingCyclePredictions: [(animal: Animal, date: Date)] {
        var predictions: [(animal: Animal, date: Date)] = []
        
        for animal in dataStore.animals {
            if let prediction = dataStore.predictNextCycle(animalId: animal.id) {
                predictions.append((animal: animal, date: prediction))
            }
        }
        
        // 日付が近い順にソート
        return predictions.sorted(by: { $0.date < $1.date })
    }
}

// イベントカード（カレンダーイベント用）
struct EnhancedEventCard: View {
    let event: ScheduledEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(event.color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: event.icon)
                        .font(.system(size: 16))
                        .foregroundColor(event.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.animalName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(event.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Text(formatDate(event.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(height: 100)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        // 時刻がない場合は日付のみ
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        if components.hour == 0 && components.minute == 0 {
            formatter.dateFormat = "M/d"
        }
        return formatter.string(from: date)
    }
}

struct EmptyAnimalView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "pawprint.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("ペットが登録されていません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("ペットを追加して、健康管理を始めましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: AddAnimalView()) {
                Text("ペットを追加")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AnimalCard: View {
    let animal: Animal
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(animal.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                if let imageUrl = animal.imageUrl, let uiImage = loadImage(from: imageUrl) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "pawprint.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(animal.color)
                }
            }
            
            Text(animal.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(animal.species)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(animal.gender.rawValue)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(genderColor(animal.gender).opacity(0.2))
                .foregroundColor(genderColor(animal.gender))
                .cornerRadius(6)
        }
        .padding()
        .frame(width: 120, height: 180)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func genderColor(_ gender: Animal.Gender) -> Color {
        switch gender {
        case .male:
            return .blue
        case .female:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    private func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

struct PredictionCard: View {
    let animal: Animal
    let date: Date
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(animal.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                if let imageUrl = animal.imageUrl, let uiImage = loadImage(from: imageUrl) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "pawprint.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(animal.color)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(animal.name)
                    .font(.headline)
                
                Text("\(animal.species) (\(animal.gender.rawValue))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text(formatDate(date))
                    .font(.headline)
                
                Text(daysUntil(date))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(daysUntilColor(date).opacity(0.2))
                    .foregroundColor(daysUntilColor(date))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func daysUntil(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        
        guard let days = components.day else { return "" }
        
        if days == 0 {
            return "今日"
        } else if days < 0 {
            return "\(abs(days))日前"
        } else {
            return "あと\(days)日"
        }
    }
    
    private func daysUntilColor(_ date: Date) -> Color {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        
        guard let days = components.day else { return .gray }
        
        if days <= 0 {
            return .red
        } else if days <= 3 {
            return .orange
        } else if days <= 7 {
            return .blue
        } else {
            return .green
        }
    }
    
    private func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

struct LatestHealthCard: View {
    let record: HealthRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                
                Text("最新の健康記録")
                    .font(.headline)
                
                Spacer()
                
                Text(formatDate(record.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                if let weight = record.weight {
                    VStack(spacing: 5) {
                        Text("体重")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.1f", weight)) kg")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                if let temperature = record.temperature {
                    VStack(spacing: 5) {
                        Text("体温")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.1f", temperature)) °C")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                VStack(spacing: 5) {
                    Text("食欲")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(record.appetite.description)
                        .font(.headline)
                        .foregroundColor(appetiteColor(record.appetite))
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 5) {
                    Text("活動量")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(record.activityLevel.description)
                        .font(.headline)
                        .foregroundColor(activityColor(record.activityLevel))
                }
                .frame(maxWidth: .infinity)
            }
            
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    
    private func appetiteColor(_ appetite: HealthRecord.Appetite) -> Color {
        switch appetite {
        case .poor:
            return .red
        case .normal:
            return .orange
        case .good:
            return .green
        }
    }
    
    private func activityColor(_ activity: HealthRecord.ActivityLevel) -> Color {
        switch activity {
        case .low:
            return .blue
        case .normal:
            return .purple
        case .high:
            return .pink
        }
    }
}