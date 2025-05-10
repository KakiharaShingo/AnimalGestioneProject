import SwiftUI

// First, define SimpleCalendarView
struct SimpleCalendarView: View {
    @Binding var selectedDate: Date
    @State private var monthOffset = 0
    
    private var calendar = Calendar.current
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { monthOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(monthYearString(for: currentMonth))
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { monthOffset += 1 }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                ForEach(days, id: \.self) { day in
                    if day == 0 {
                        Text("")
                    } else {
                        Button(action: {
                            selectedDate = date(for: day)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isSelected(day: day) ? Color.blue : Color.clear)
                                    .frame(width: 35, height: 35)
                                
                                Text("\(day)")
                                    .foregroundColor(isSelected(day: day) ? .white : .primary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var currentMonth: Date {
        let today = Date()
        return calendar.date(byAdding: .month, value: monthOffset, to: today) ?? today
    }
    
    private var weekdaySymbols: [String] {
        return calendar.veryShortWeekdaySymbols
    }
    
    private var days: [Int] {
        let startOfMonth = startOfMonth(for: currentMonth)
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        // 0はスペースを表す
        var days = Array(repeating: 0, count: firstWeekday - 1)
        days.append(contentsOf: 1...range.count)
        
        return days
    }
    
    private func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components)!
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
    
    private func date(for day: Int) -> Date {
        let components = DateComponents(year: calendar.component(.year, from: currentMonth),
                                       month: calendar.component(.month, from: currentMonth),
                                       day: day)
        return calendar.date(from: components)!
    }
    
    private func isSelected(day: Int) -> Bool {
        guard day > 0 else { return false }
        let dayDate = date(for: day)
        return calendar.isDate(dayDate, inSameDayAs: selectedDate)
    }
}

// Helper view components
struct AnimalRowView: View {
    let animal: Animal
    
    var body: some View {
        HStack {
            if let imageUrl = animal.imageUrl, let uiImage = loadImage(from: imageUrl) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "pawprint.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(animal.name)
                    .font(.headline)
                Text("\(animal.species) (\(animal.gender.rawValue))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

struct AnimalCardView: View {
    let animal: Animal
    
    var body: some View {
        VStack {
            if let imageUrl = animal.imageUrl, let uiImage = loadImage(from: imageUrl) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "pawprint.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
            
            Text(animal.name)
                .font(.headline)
                .lineLimit(1)
            
            Text(animal.species)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text(animal.gender.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(genderColor(animal.gender).opacity(0.2))
                .foregroundColor(genderColor(animal.gender))
                .cornerRadius(4)
        }
        .frame(height: 180)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    private func genderColor(_ gender: Animal.Gender) -> Color {
        switch gender {
        case .male:
            return .blue
        case .female:
            return .pink
        case .unknown:
            return .gray
        }
    }
}

// Main AnimalListView
struct AnimalListView: View {
    @EnvironmentObject var dataStore: AnimalDataStore
    @State private var showingAddAnimal = false
    @State private var selectedDate = Date()
    
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // カレンダー
                    VStack(alignment: .leading) {
                        Text("カレンダー")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        SimpleCalendarView(selectedDate: $selectedDate)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // ペット一覧
                    VStack(alignment: .leading) {
                        Text("マイペット")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if dataStore.animals.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "pawprint.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                                
                                Text("ペットが登録されていません")
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    showingAddAnimal = true
                                }) {
                                    Text("ペットを追加")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(dataStore.animals) { animal in
                                    NavigationLink(destination: AnimalDetailView(animal: animal)) {
                                        AnimalCardView(animal: animal)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 生理周期予測
                    if !dataStore.animals.isEmpty && !dataStore.physiologicalCycles.isEmpty {
                        VStack(alignment: .leading) {
                            Text("近日の生理周期予測")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(upcomingCyclePredictions, id: \.animal.id) { prediction in
                                HStack {
                                    if let imageUrl = prediction.animal.imageUrl, let uiImage = loadImage(from: imageUrl) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "pawprint.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(prediction.animal.name)
                                            .font(.headline)
                                        
                                        Text("次回予測: \(formatDate(prediction.date))")
                                            .font(.subheadline)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(daysUntil(prediction.date))
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(daysUntilColor(prediction.date).opacity(0.2))
                                        .foregroundColor(daysUntilColor(prediction.date))
                                        .cornerRadius(4)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                            
                            if upcomingCyclePredictions.isEmpty {
                                Text("予測可能な生理周期はありません")
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("動物生理管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAnimal = true }) {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAnimal) {
                AddAnimalView()
            }
        }
    }
    
    private var upcomingCyclePredictions: [(animal: Animal, date: Date)] {
        var predictions: [(animal: Animal, date: Date)] = []
        
        for animal in dataStore.animals {
            if let prediction = dataStore.predictNextCycle(animalId: animal.id) {
                predictions.append((animal: animal, date: prediction))
            }
        }
        
        return predictions.sorted(by: { $0.date < $1.date })
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
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