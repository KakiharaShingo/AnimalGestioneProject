import SwiftUI

public struct EnhancedCalendarView: View {
    @EnvironmentObject var dataStore: CoreDataStore
    @Binding var selectedDate: Date
    @State private var monthOffset = 0
    @State private var eventsForSelectedDate: [ScheduledEvent] = []
    @State private var showingAddSchedule = false
    @State private var selectedEventForEdit: ScheduledEvent? = nil
    @State private var showingEditSheet = false
    
    // イニシャライザを明示的に宣言してpublicにする
    public init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
    }
    
    private var calendar = Calendar.current
    
    public var body: some View {
        VStack(spacing: 15) {
            // 月選択ヘッダー
            HStack {
                Button(action: { 
                    withAnimation {
                        monthOffset -= 1
                        updateEvents()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text(monthYearString(for: currentMonth))
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { 
                    withAnimation {
                        monthOffset += 1
                        updateEvents()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            
            // 曜日ヘッダー
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // 日グリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(days, id: \.self) { day in
                    if day == 0 {
                        Color.clear
                            .frame(height: 40)
                    } else {
                        VStack(spacing: 4) {
                            // 日付
                            ZStack {
                                Circle()
                                    .fill(isSelected(day: day) ? Color.accentColor : Color.clear)
                                    .frame(width: 32, height: 32)
                                
                                Text("\(day)")
                                    .font(.system(size: 16, weight: isSelected(day: day) ? .bold : .medium))
                                    .foregroundColor(isSelected(day: day) ? .white : isToday(day: day) ? .accentColor : .primary)
                            }
                            
                            // イベントのインジケーター
                            let dayDate = date(for: day)
                            if dataStore.hasAnyEventOnDate(dayDate) {
                                VStack(spacing: 2) {
                                    // イベント型を表示
                                    let allEvents = dataStore.scheduledEventsOn(date: dayDate)
                                    
                                    // 動物なごとに色を表示 (同じ動物の色は縦りを省く)
                                    let animalGroups = Dictionary(grouping: allEvents) { $0.animalId }
                                    
                                    // 表示する色を取得
                                    let colors: [Color] = animalGroups.keys.compactMap { animalId in
                                        dataStore.animals.first(where: { $0.id == animalId })?.color
                                    }.prefix(3).map { $0 }
                                    
                                    HStack(spacing: 2) {
                                        ForEach(0..<colors.count, id: \.self) { index in
                                            Circle()
                                                .fill(colors[index])
                                                .frame(width: 8, height: 8) // サイズを大きく
                                                .shadow(color: colors[index].opacity(0.5), radius: 1, x: 0, y: 0) // 影を追加して強調
                                        }
                                        
                                        if allEvents.count > 3 {
                                            Text("+\(allEvents.count - 3)")
                                                .font(.system(size: 8))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    // 件数を表示
                                    if allEvents.count > 0 {
                                        Text("\(allEvents.count)件")
                                            .font(.system(size: 8))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .frame(height: 40)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                selectedDate = date(for: day)
                                updateEvents()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // 選択された日付のタイトルとスケジュール追加ボタン
            HStack {
                Text(formatFullDate(selectedDate))
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingAddSchedule = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // 選択された日のイベントリスト
            if eventsForSelectedDate.isEmpty {
                VStack {
                    Text("この日に予定はありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    // 動物ごとにグループ化して表示
                    let groupedEvents = Dictionary(grouping: eventsForSelectedDate) { $0.animalId }
                    
                    ForEach(groupedEvents.keys.sorted(), id: \.self) { animalId in
                        if let animal = dataStore.animals.first(where: { $0.id == animalId }),
                           let events = groupedEvents[animalId] {
                            VStack(alignment: .leading, spacing: 8) {
                                // 動物名をヘッダーとして表示
                                Text(animal.name)
                                    .font(.headline)
                                    .foregroundColor(animal.color)
                                    .padding(.horizontal)
                                
                                // 該当動物のイベントを表示
                                ForEach(events) { event in
                                    EventCard(event: event, onDelete: {
                                        updateEvents()
                                    })
                                    .onTapGesture {
                                        selectedEventForEdit = event
                                        showingEditSheet = true
                                    }
                                }
                            }
                            .padding(.bottom, 10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            updateEvents()
        }
        .onChange(of: selectedDate) { _ in
            updateEvents()
        }
        .sheet(isPresented: $showingAddSchedule) {
            ScheduleAddView(animalId: nil, date: selectedDate, onSave: {
                updateEvents()
            })
        }
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            selectedEventForEdit = nil
        }) {
            if let event = selectedEventForEdit {
                ScheduleEditView(event: event, onSave: {
                    updateEvents()
                })
            }
        }
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
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日(EEEE)"
        formatter.locale = Locale(identifier: "ja_JP")
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
    
    private func isToday(day: Int) -> Bool {
        guard day > 0 else { return false }
        let dayDate = date(for: day)
        return calendar.isDate(dayDate, inSameDayAs: Date())
    }
    
    private func updateEvents() {
        eventsForSelectedDate = dataStore.scheduledEventsOn(date: selectedDate)
    }
    

    
    // 日付に関連する動物の色を取得
    private func getAccentColorForDate(_ date: Date) -> Color {
        let events = dataStore.scheduledEventsOn(date: date)
        
        // 動物ごとにグループ化
        let animalGroups = Dictionary(grouping: events) { $0.animalId }
        
        // 複数の動物がいる場合は、最初の動物の色を使用
        if let firstAnimalId = animalGroups.keys.first,
           let firstEvent = animalGroups[firstAnimalId]?.first {
            return firstEvent.color
        }
        
        // イベントがない場合はデフォルトのアクセントカラー
        return Color.accentColor
    }
}

// イベントカード表示用
struct EventCard: View {
    let event: ScheduledEvent
    @State private var showDeleteConfirmation = false
    @EnvironmentObject var dataStore: CoreDataStore
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // アイコンと色表示
            ZStack {
                Circle()
                    .fill(event.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: event.icon)
                    .font(.system(size: 18))
                    .foregroundColor(event.color)
            }
            
            // イベント内容
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(event.animalName)
                    .font(.subheadline)
                    .foregroundColor(event.color)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 時間があれば表示
            Text(formatTime(event.date))
                .font(.caption)
                .foregroundColor(.secondary)
                
            // 削除ボタンを追加
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(Color.red.opacity(0.7))
                    .font(.caption)
                    .padding(8)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding()
        .background(event.color.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(event.color.opacity(0.2), lineWidth: 1)
        )
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("予定を削除"),
                message: Text("この予定を削除してもよろしいですか？"),
                primaryButton: .destructive(Text("削除")) {
                    deleteEvent()
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        // 時間の指定がない場合は空文字列を返す
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        if components.hour == 0 && components.minute == 0 {
            return "終日"
        } else {
            return formatter.string(from: date)
        }
    }
    
    private func deleteEvent() {
        switch event.type {
        case .vaccine(let record):
            dataStore.deleteVaccineRecord(record)
        case .grooming(let record):
            dataStore.deleteGroomingRecord(record)
        case .checkup(let record):
            dataStore.deleteCheckupRecord(record)
        case .medication(let record):
            dataStore.deleteMedicationRecord(record)
        case .other(let record):
            dataStore.deleteOtherRecord(record)
        case .physiologicalCycle(let cycle, _, _):
            if let cycle = cycle {
                dataStore.deleteCycle(id: cycle.id)
            }
        }
        
        // 削除後にイベントリストを更新するコールバックを実行
        if let onDelete = onDelete {
            onDelete()
        }
    }
}

// スケジュール追加画面
struct ScheduleAddView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    
    let animalId: UUID?
    let date: Date
    let onSave: () -> Void
    
    @State private var selectedAnimal: Animal?
    @State private var title = ""
    @State private var scheduleType: ScheduleType = .vaccine
    @State private var scheduledDate: Date
    @State private var notes = ""
    
    // 再利用できるように列挙型をStructの外部に移動
enum ScheduleType: String, CaseIterable, Identifiable {
        case vaccine = "ワクチン"
        case grooming = "トリミング"
        case checkup = "健康診断"
        case medication = "投薬"
        case other = "その他"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .vaccine: return "syringe"
            case .grooming: return "scissors"
            case .checkup: return "stethoscope"
            case .medication: return "pill"
            case .other: return "calendar.badge.plus"
            }
        }
        
        var color: Color {
            switch self {
            case .vaccine: return .green
            case .grooming: return .purple
            case .checkup: return .blue
            case .medication: return .orange
            case .other: return .gray
            }
        }
    }
    
    init(animalId: UUID?, date: Date, onSave: @escaping () -> Void) {
        self.animalId = animalId
        self.date = date
        self.onSave = onSave
        self._scheduledDate = State(initialValue: date)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 動物を選択（特定の動物が指定されていない場合のみ表示）
                if animalId == nil {
                    Section(header: Text("ペット")) {
                        Picker("ペットを選択", selection: $selectedAnimal) {
                            Text("選択してください").tag(nil as Animal?)
                            ForEach(dataStore.animals) { animal in
                                Text(animal.name).tag(animal as Animal?)
                            }
                        }
                    }
                }
                
                Section(header: Text("予定の詳細")) {
                    Picker("予定の種類", selection: $scheduleType) {
                        ForEach(ScheduleType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .foregroundColor(type.color)
                                .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("タイトル", text: $title)
                    
                    DatePicker("日時", selection: $scheduledDate)
                }
                
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("予定を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSchedule()
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
    
    private var isSaveDisabled: Bool {
        // ペットが選択されていないか(指定されていない場合)、タイトルが空の場合は保存できない
        return (animalId == nil && selectedAnimal == nil) || title.isEmpty
    }
    
    private func saveSchedule() {
        // 保存先の動物ID（直接指定されているか、選択されたもの）
        let targetAnimalId = animalId ?? selectedAnimal?.id
        
        guard let finalAnimalId = targetAnimalId else { return }
        
        // 動物の色を取得
        let animalColor = selectedAnimal?.color ?? dataStore.animals.first(where: { $0.id == finalAnimalId })?.color ?? Color.gray
        
        // スケジュールタイプに応じて保存
        switch scheduleType {
        case .vaccine:
            let vaccineRecord = VaccineRecord(
                id: UUID(),
                animalId: finalAnimalId,
                date: scheduledDate,
                vaccineName: title,
                nextScheduledDate: nil,
                interval: nil,
                notes: notes.isEmpty ? nil : notes,
                color: animalColor // 動物の色を設定
            )
            dataStore.addVaccineRecord(vaccineRecord)
            
        case .grooming:
            let groomingRecord = GroomingRecord(
                id: UUID(),
                animalId: finalAnimalId,
                date: scheduledDate,
                groomingType: title,
                nextScheduledDate: nil,
                interval: nil,
                notes: notes.isEmpty ? nil : notes,
                color: animalColor // 動物の色を設定
            )
            dataStore.addGroomingRecord(groomingRecord)
            
        case .checkup:
            let checkupRecord = CheckupRecord(
                id: UUID(),
                animalId: finalAnimalId,
                date: scheduledDate,
                checkupType: title,
                nextScheduledDate: nil,
                interval: nil,
                notes: notes.isEmpty ? nil : notes,
                color: animalColor // 動物の色を設定
            )
            dataStore.addCheckupRecord(checkupRecord)
            
        case .medication:
            let medicationRecord = MedicationRecord(
                id: UUID(),
                animalId: finalAnimalId,
                date: scheduledDate,
                medicationName: title,
                nextScheduledDate: nil,
                interval: nil,
                notes: notes.isEmpty ? nil : notes,
                color: animalColor // 動物の色を設定
            )
            dataStore.addMedicationRecord(medicationRecord)
            
        case .other:
            let otherRecord = OtherRecord(
                id: UUID(),
                animalId: finalAnimalId,
                date: scheduledDate,
                title: title,
                nextScheduledDate: nil,
                interval: nil,
                notes: notes.isEmpty ? nil : notes,
                color: animalColor // 動物の色を設定
            )
            dataStore.addOtherRecord(otherRecord)
        }
        
        onSave()
        presentationMode.wrappedValue.dismiss()
    }
}