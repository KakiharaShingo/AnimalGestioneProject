import SwiftUI

struct PhysiologicalCycleView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    @State private var showingAddCycle = false
    @State private var selectedCycle: PhysiologicalCycle?
    
    let animalId: UUID
    
    var body: some View {
        NavigationView {
            List {
                // 生理予測の説明セクション
                Section(header: Text("生理予測について")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("生理予測のためには、以下の条件が必要です：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("・過去3回以上の生理周期データ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("・周期の規則性がある程度安定していること")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                // 生理周期を追加するためのボタンセクション
                Section {
                    Button(action: {
                        showingAddCycle = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("新しい生理周期を記録")
                        }
                    }
                }
                
                // 生理周期を一覧表示
                Section(header: Text("生理周期履歴")) {
                    if dataStore.cyclesForAnimal(id: animalId).isEmpty {
                        Text("記録された生理周期はありません")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(dataStore.cyclesForAnimal(id: animalId)) { cycle in
                            PhysiologicalCycleRow(cycle: cycle)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCycle = cycle
                                }
                                .contextMenu {
                                    Button(action: {
                                        selectedCycle = cycle
                                    }) {
                                        Label("編集", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        dataStore.deleteCycle(id: cycle.id)
                                    }) {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                        }
                        .onDelete(perform: deleteCycles)
                    }
                }
            }
            .navigationTitle("生理周期")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCycle = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCycle) {
                AddPhysiologicalCycleView(animalId: animalId)
            }
            .sheet(item: $selectedCycle) { cycle in
                EditPhysiologicalCycleView(cycle: cycle) { updatedCycle in
                    dataStore.updateCycle(updatedCycle)
                }
            }
        }
    }
    
    private func deleteCycles(at offsets: IndexSet) {
        let cycles = dataStore.cyclesForAnimal(id: animalId)
        offsets.forEach { index in
            let cycle = cycles[index]
            dataStore.deleteCycle(id: cycle.id)
        }
    }
}

struct AddPhysiologicalCycleView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    
    @State private var startDate = Date()
    @State private var endDate: Date?
    @State private var hasEndDate = false
    @State private var intensity = PhysiologicalCycle.Intensity.medium
    @State private var notes = ""
    
    let animalId: UUID
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                
                Toggle("終了日を設定", isOn: $hasEndDate)
                
                if hasEndDate {
                    DatePicker("終了日", selection: Binding(
                        get: { self.endDate ?? self.startDate.addingTimeInterval(86400) },
                        set: { self.endDate = $0 }
                    ), displayedComponents: .date)
                }
                
                Picker("強度", selection: $intensity) {
                    Text("軽度").tag(PhysiologicalCycle.Intensity.light)
                    Text("中度").tag(PhysiologicalCycle.Intensity.medium)
                    Text("重度").tag(PhysiologicalCycle.Intensity.heavy)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("生理周期を追加")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveCycle()
                    }
                }
            }
        }
    }
    
    private func saveCycle() {
        let cycle = PhysiologicalCycle(
            animalId: animalId,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            intensity: intensity,
            notes: notes.isEmpty ? nil : notes
        )
        
        dataStore.addCycle(cycle)
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditPhysiologicalCycleView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var startDate: Date
    @State private var endDate: Date?
    @State private var hasEndDate: Bool
    @State private var intensity: PhysiologicalCycle.Intensity
    @State private var notes: String
    
    private var originalCycle: PhysiologicalCycle
    private var onSave: (PhysiologicalCycle) -> Void
    
    init(cycle: PhysiologicalCycle, onSave: @escaping (PhysiologicalCycle) -> Void) {
        self.originalCycle = cycle
        self.onSave = onSave
        
        _startDate = State(initialValue: cycle.startDate)
        _endDate = State(initialValue: cycle.endDate)
        _hasEndDate = State(initialValue: cycle.endDate != nil)
        _intensity = State(initialValue: cycle.intensity)
        _notes = State(initialValue: cycle.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                
                Toggle("終了日を設定", isOn: $hasEndDate)
                
                if hasEndDate {
                    DatePicker("終了日", selection: Binding(
                        get: { self.endDate ?? self.startDate.addingTimeInterval(86400) },
                        set: { self.endDate = $0 }
                    ), displayedComponents: .date)
                }
                
                Picker("強度", selection: $intensity) {
                    Text("軽度").tag(PhysiologicalCycle.Intensity.light)
                    Text("中度").tag(PhysiologicalCycle.Intensity.medium)
                    Text("重度").tag(PhysiologicalCycle.Intensity.heavy)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("生理周期を編集")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveCycle()
                    }
                }
            }
        }
    }
    
    private func saveCycle() {
        var updatedCycle = originalCycle
        updatedCycle.startDate = startDate
        updatedCycle.endDate = hasEndDate ? endDate : nil
        updatedCycle.intensity = intensity
        updatedCycle.notes = notes.isEmpty ? nil : notes
        
        onSave(updatedCycle)
        presentationMode.wrappedValue.dismiss()
    }
}