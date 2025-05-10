import SwiftUI

struct WeightRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    let animalId: UUID
    
    @State private var timeRange: TimeRange = .month
    @State private var weightChartData: [WeightChartPoint] = []
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "週間"
        case month = "1ヶ月"
        case threeMonths = "3ヶ月"
        case sixMonths = "6ヶ月"
        case year = "1年"
        case all = "すべて"
        
        var id: String { self.rawValue }
        
        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .year: return 365
            case .all: return nil
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // グラフタイトルと期間選択
                HStack {
                    Text("体重の推移")
                        .font(.headline)
                    
                    Spacer()
                    
                    Picker("期間", selection: $timeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: timeRange) { _ in
                        updateChartData()
                    }
                }
                .padding(.horizontal)
                
                // グラフ
                VStack {
                    if weightChartData.isEmpty {
                        Text("表示するデータがありません")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        WeightRecordChart(data: weightChartData)
                            .frame(height: 250)
                            .padding(.vertical)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // 統計情報
                if !weightChartData.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("統計")
                            .font(.headline)
                        
                        HStack {
                            StatCard(
                                title: "最新",
                                value: String(format: "%.1f kg", weightChartData.last?.weight ?? 0),
                                icon: "scale.3d",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "最大",
                                value: String(format: "%.1f kg", weightChartData.map { $0.weight }.max() ?? 0),
                                icon: "arrow.up.circle",
                                color: .orange
                            )
                            
                            StatCard(
                                title: "最小",
                                value: String(format: "%.1f kg", weightChartData.map { $0.weight }.min() ?? 0),
                                icon: "arrow.down.circle",
                                color: .green
                            )
                        }
                        
                        // 変化量
                        if weightChartData.count >= 2 {
                            let first = weightChartData.first?.weight ?? 0
                            let last = weightChartData.last?.weight ?? 0
                            let diff = last - first
                            let diffPercent = first > 0 ? (diff / first) * 100 : 0
                            
                            HStack {
                                Spacer()
                                
                                VStack(alignment: .center, spacing: 4) {
                                    Text("期間内の変化")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Image(systemName: diff > 0 ? "arrow.up" : (diff < 0 ? "arrow.down" : "arrow.forward"))
                                            .foregroundColor(diff > 0 ? .red : (diff < 0 ? .blue : .gray))
                                        
                                        Text(String(format: "%+.1f kg (%+.1f%%)", diff, diffPercent))
                                            .font(.headline)
                                            .foregroundColor(diff > 0 ? .red : (diff < 0 ? .blue : .gray))
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                
                // メッセージ
                Text("健康記録から体重情報を取得しています。\n体重を記録するには、健康記録から入力してください。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("体重記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                updateChartData()
            }
        }
    }
    
    private func updateChartData() {
        // 健康記録から体重データを取得
        let records = dataStore.healthRecordsForAnimal(id: animalId)
        
        // 体重データがあるレコードだけをフィルタリング
        let weightRecords = records.filter { $0.weight != nil }
        
        // 期間でフィルタリング
        var filteredRecords = weightRecords
        if let days = timeRange.days {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            filteredRecords = weightRecords.filter { $0.date >= cutoffDate }
        }
        
        // チャートデータに変換
        weightChartData = filteredRecords.compactMap { record in
            guard let weight = record.weight else { return nil }
            return WeightChartPoint(date: record.date, weight: weight)
        }
        
        // 日付でソート (古い順)
        weightChartData.sort { $0.date < $1.date }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// チャートで使用するデータ構造
struct WeightChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// 体重チャート
struct WeightRecordChart: View {
    let data: [WeightChartPoint]
    
    var body: some View {
        if data.isEmpty {
            Text("データがありません")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            VStack {
                GeometryReader { geometry in
                    ZStack {
                        // Y軸のグリッドライン
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(0..<5) { i in
                                Divider()
                                Spacer()
                                    .frame(height: i < 4 ? geometry.size.height / 5 : 0)
                            }
                        }
                        
                        // 折れ線グラフ
                        Path { path in
                            let xStep = geometry.size.width / CGFloat(max(1, data.count - 1))
                            let yRange = maxWeight - minWeight
                            
                            for (index, point) in data.enumerated() {
                                let x = xStep * CGFloat(index)
                                let y = geometry.size.height * (1 - CGFloat((point.weight - minWeight) / max(0.1, yRange)))
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        
                        // データポイント
                        ForEach(0..<data.count, id: \.self) { index in
                            let point = data[index]
                            let xStep = geometry.size.width / CGFloat(max(1, data.count - 1))
                            let x = xStep * CGFloat(index)
                            let yRange = maxWeight - minWeight
                            let y = geometry.size.height * (1 - CGFloat((point.weight - minWeight) / max(0.1, yRange)))
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                        
                        // Y軸のラベル
                        VStack(alignment: .leading) {
                            Text(String(format: "%.1f kg", maxWeight))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .offset(x: -30, y: 0)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f kg", minWeight))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .offset(x: -30, y: 0)
                        }
                    }
                }
                
                // X軸のラベル
                HStack(spacing: 0) {
                    ForEach(0..<data.count, id: \.self) { index in
                        if data.count <= 5 || index % max(1, data.count / 5) == 0 {
                            Text(data[index].formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        } else {
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var minWeight: Double {
        guard let min = data.map({ $0.weight }).min() else { return 0 }
        // 最小値より少し下を表示範囲の下限にする
        return max(0, min - 0.5)
    }
    
    private var maxWeight: Double {
        guard let max = data.map({ $0.weight }).max() else { return 10 }
        // 最大値より少し上を表示範囲の上限にする
        return max + 0.5
    }
}
