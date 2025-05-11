import SwiftUI

struct ScheduleEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    
    let event: ScheduledEvent
    let onSave: () -> Void
    
    @State private var title = ""
    @State private var scheduledDate: Date = Date()
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var scheduleInterval: Int? = nil
    @State private var nextScheduledDate: Date? = nil
    
    init(event: ScheduledEvent, onSave: @escaping () -> Void) {
        self.event = event
        self.onSave = onSave
        
        // 初期値を設定
        switch event.type {
        case .vaccine(let record):
            _title = State(initialValue: record.vaccineName)
            _scheduledDate = State(initialValue: record.date)
            _notes = State(initialValue: record.notes ?? "")
            _scheduleInterval = State(initialValue: record.interval)
            _nextScheduledDate = State(initialValue: record.nextScheduledDate)
        case .grooming(let record):
            _title = State(initialValue: record.groomingType ?? "")
            _scheduledDate = State(initialValue: record.date)
            _notes = State(initialValue: record.notes ?? "")
            _scheduleInterval = State(initialValue: record.interval)
            _nextScheduledDate = State(initialValue: record.nextScheduledDate)
        case .checkup(let record):
            _title = State(initialValue: record.checkupType)
            _scheduledDate = State(initialValue: record.date)
            _notes = State(initialValue: record.notes ?? "")
            _scheduleInterval = State(initialValue: record.interval)
            _nextScheduledDate = State(initialValue: record.nextScheduledDate)
        case .medication(let record):
            _title = State(initialValue: record.medicationName)
            _scheduledDate = State(initialValue: record.date)
            _notes = State(initialValue: record.notes ?? "")
            _scheduleInterval = State(initialValue: record.interval)
            _nextScheduledDate = State(initialValue: record.nextScheduledDate)
        case .other(let record):
            _title = State(initialValue: record.title)
            _scheduledDate = State(initialValue: record.date)
            _notes = State(initialValue: record.notes ?? "")
            _scheduleInterval = State(initialValue: record.interval)
            _nextScheduledDate = State(initialValue: record.nextScheduledDate)
        case .physiologicalCycle(let cycle, _, _):
            if let cycle = cycle {
                _title = State(initialValue: "生理周期")
                _scheduledDate = State(initialValue: cycle.startDate)
                _notes = State(initialValue: cycle.notes ?? "")
            } else {
                _title = State(initialValue: "生理周期 (予測)")
                _scheduledDate = State(initialValue: event.date)
                _notes = State(initialValue: "")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("予定の詳細")) {
                    TextField("タイトル", text: $title)
                    
                    DatePicker("日時", selection: $scheduledDate)
                    
                    // 次回予定の設定（生理周期以外で表示）
                    if case .physiologicalCycle(_, _, _) = event.type {} else {
                        Toggle("次回予定を設定", isOn: Binding(
                            get: { nextScheduledDate != nil },
                            set: { if $0 { nextScheduledDate = Calendar.current.date(byAdding: .day, value: scheduleInterval ?? 30, to: scheduledDate) } else { nextScheduledDate = nil } }
                        ))
                        
                        if nextScheduledDate != nil {
                            HStack {
                                Text("間隔（日）")
                                TextField("30", value: Binding(
                                    get: { scheduleInterval ?? 30 },
                                    set: { 
                                        scheduleInterval = $0
                                        if let days = scheduleInterval {
                                            nextScheduledDate = Calendar.current.date(byAdding: .day, value: days, to: scheduledDate)
                                        }
                                    }
                                ), formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                            }
                            
                            DatePicker("次回予定日", selection: Binding(
                                get: { nextScheduledDate ?? Date() },
                                set: { 
                                    nextScheduledDate = $0
                                    if let nextDate = nextScheduledDate {
                                        let days = Calendar.current.dateComponents([.day], from: scheduledDate, to: nextDate).day ?? 30
                                        scheduleInterval = days
                                    }
                                }
                            ))
                        }
                    }
                }
                
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("予定を編集")
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
                    .disabled(title.isEmpty)
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
    
    private func saveSchedule() {
        switch event.type {
        case .vaccine(var record):
            record.vaccineName = title
            record.date = scheduledDate
            record.nextScheduledDate = nextScheduledDate
            record.interval = scheduleInterval
            record.notes = notes.isEmpty ? nil : notes
            dataStore.updateVaccineRecord(record)
            
        case .grooming(var record):
            record.groomingType = title
            record.date = scheduledDate
            record.nextScheduledDate = nextScheduledDate
            record.interval = scheduleInterval
            record.notes = notes.isEmpty ? nil : notes
            dataStore.updateGroomingRecord(record)
            
        case .checkup(var record):
            record.checkupType = title
            record.date = scheduledDate
            record.nextScheduledDate = nextScheduledDate
            record.interval = scheduleInterval
            record.notes = notes.isEmpty ? nil : notes
            dataStore.updateCheckupRecord(record)
            
        case .medication(var record):
            record.medicationName = title
            record.date = scheduledDate
            record.nextScheduledDate = nextScheduledDate
            record.interval = scheduleInterval
            record.notes = notes.isEmpty ? nil : notes
            dataStore.updateMedicationRecord(record)
            
        case .other(var record):
            record.title = title
            record.date = scheduledDate
            record.nextScheduledDate = nextScheduledDate
            record.interval = scheduleInterval
            record.notes = notes.isEmpty ? nil : notes
            dataStore.updateOtherRecord(record)
            
        case .physiologicalCycle(let cycle, _, _):
            if let cycleRecord = cycle {
                var updatedCycle = cycleRecord
                updatedCycle.startDate = scheduledDate
                updatedCycle.notes = notes.isEmpty ? nil : notes
                dataStore.updateCycle(updatedCycle)
            }
        }
        
        onSave()
        presentationMode.wrappedValue.dismiss()
    }
}
