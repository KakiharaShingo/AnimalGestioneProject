import SwiftUI

struct HealthChartView: View {
    @EnvironmentObject var dataStore: CoreDataStore
    let animalId: UUID
    @State private var chartType: ChartType = .weight
    @State private var timeRange: TimeRange = .month
    
    enum ChartType: String, CaseIterable {
        case weight = "体重"
        case temperature = "体温"
        case appetite = "食欲"
        case activity = "活動量"
    }
    
    enum TimeRange: String, CaseIterable {
        case week = "1週間"
        case month = "1ヶ月"
        case threeMonths = "3ヶ月"
        case year = "1年"
        case all = "すべて"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 操作パネル
            VStack(spacing: 10) {
                // チャートタイプ選択
                Picker("チャートタイプ", selection: $chartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // 期間選択
                Picker("期間", selection: $timeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            // チャート表示
            ChartContainer(animalId: animalId, chartType: chartType, timeRange: timeRange)
                .frame(height: 250)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            
            // 統計情報
            StatisticsView(animalId: animalId, chartType: chartType, timeRange: timeRange)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
        }
        .navigationTitle("健康グラフ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChartContainer: View {
    @EnvironmentObject var dataStore: CoreDataStore
    let animalId: UUID
    let chartType: HealthChartView.ChartType
    let timeRange: HealthChartView.TimeRange
    
    var body: some View {
        VStack {
            if filteredRecords.isEmpty {
                Text("この期間のデータがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                switch chartType {
                case .weight:
                    WeightChart(records: filteredRecords)
                case .temperature:
                    TemperatureChart(records: filteredRecords)
                case .appetite:
                    AppetiteChart(records: filteredRecords)
                case .activity:
                    ActivityChart(records: filteredRecords)
                }
            }
        }
    }
    
    private var filteredRecords: [HealthRecord] {
        let records = dataStore.healthRecordsForAnimal(id: animalId)
        
        guard !records.isEmpty else { return [] }
        
        let now = Date()
        let calendar = Calendar.current
        
        switch timeRange {
        case .week:
            let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return records.filter { $0.date >= oneWeekAgo }
        case .month:
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return records.filter { $0.date >= oneMonthAgo }
        case .threeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return records.filter { $0.date >= threeMonthsAgo }
        case .year:
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return records.filter { $0.date >= oneYearAgo }
        case .all:
            return records
        }
    }
}

struct StatisticsView: View {
    @EnvironmentObject var dataStore: CoreDataStore
    let animalId: UUID
    let chartType: HealthChartView.ChartType
    let timeRange: HealthChartView.TimeRange
    
    var body: some View {
        VStack(spacing: 15) {
            Text("統計情報")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if filteredRecords.isEmpty {
                Text("この期間のデータがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                switch chartType {
                case .weight:
                    weightStatistics
                case .temperature:
                    temperatureStatistics
                case .appetite:
                    appetiteStatistics
                case .activity:
                    activityStatistics
                }
            }
        }
    }
    
    private var filteredRecords: [HealthRecord] {
        let records = dataStore.healthRecordsForAnimal(id: animalId)
        
        guard !records.isEmpty else { return [] }
        
        let now = Date()
        let calendar = Calendar.current
        
        switch timeRange {
        case .week:
            let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return records.filter { $0.date >= oneWeekAgo }
        case .month:
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return records.filter { $0.date >= oneMonthAgo }
        case .threeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return records.filter { $0.date >= threeMonthsAgo }
        case .year:
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return records.filter { $0.date >= oneYearAgo }
        case .all:
            return records
        }
    }
    
    private var weightStatistics: some View {
        let weights = filteredRecords.compactMap { $0.weight }
        
        guard !weights.isEmpty else {
            return AnyView(Text("体重データがありません").foregroundColor(.secondary))
        }
        
        let maxWeight = weights.max() ?? 0
        let minWeight = weights.min() ?? 0
        let avgWeight = weights.reduce(0, +) / Double(weights.count)
        
        let latestWeight = filteredRecords.first?.weight ?? 0
        let firstWeight = filteredRecords.last?.weight ?? 0
        let change = latestWeight - firstWeight
        let changePercent = firstWeight > 0 ? (change / firstWeight) * 100 : 0
        
        return AnyView(
            VStack(spacing: 10) {
                StatsRow(label: "最新", value: String(format: "%.1f kg", latestWeight))
                StatsRow(label: "最大", value: String(format: "%.1f kg", maxWeight))
                StatsRow(label: "最小", value: String(format: "%.1f kg", minWeight))
                StatsRow(label: "平均", value: String(format: "%.1f kg", avgWeight))
                StatsRow(
                    label: "変化",
                    value: String(format: "%+.1f kg (%+.1f%%)", change, changePercent),
                    valueColor: change > 0 ? .green : change < 0 ? .red : .primary
                )
            }
        )
    }
    
    private var temperatureStatistics: some View {
        let temperatures = filteredRecords.compactMap { $0.temperature }
        
        guard !temperatures.isEmpty else {
            return AnyView(Text("体温データがありません").foregroundColor(.secondary))
        }
        
        let maxTemp = temperatures.max() ?? 0
        let minTemp = temperatures.min() ?? 0
        let avgTemp = temperatures.reduce(0, +) / Double(temperatures.count)
        
        let latestTemp = filteredRecords.first?.temperature ?? 0
        
        return AnyView(
            VStack(spacing: 10) {
                StatsRow(label: "最新", value: String(format: "%.1f °C", latestTemp))
                StatsRow(label: "最大", value: String(format: "%.1f °C", maxTemp))
                StatsRow(label: "最小", value: String(format: "%.1f °C", minTemp))
                StatsRow(label: "平均", value: String(format: "%.1f °C", avgTemp))
            }
        )
    }
    
    private var appetiteStatistics: some View {
        let appetites = filteredRecords.map { $0.appetite.rawValue }
        
        guard !appetites.isEmpty else {
            return AnyView(Text("食欲データがありません").foregroundColor(.secondary))
        }
        
        let avgAppetite = Double(appetites.reduce(0, +)) / Double(appetites.count)
        let latestAppetite = filteredRecords.first?.appetite.description ?? "なし"
        
        // 食欲レベルのカウント
        let poorCount = appetites.filter { $0 == 1 }.count
        let normalCount = appetites.filter { $0 == 2 }.count
        let goodCount = appetites.filter { $0 == 3 }.count
        
        return AnyView(
            VStack(spacing: 10) {
                StatsRow(label: "最新", value: latestAppetite)
                StatsRow(label: "平均", value: String(format: "%.1f", avgAppetite))
                StatsRow(label: "食欲不振", value: "\(poorCount)回 (\(Int((Double(poorCount) / Double(appetites.count)) * 100))%)")
                StatsRow(label: "普通", value: "\(normalCount)回 (\(Int((Double(normalCount) / Double(appetites.count)) * 100))%)")
                StatsRow(label: "旺盛", value: "\(goodCount)回 (\(Int((Double(goodCount) / Double(appetites.count)) * 100))%)")
            }
        )
    }
    
    private var activityStatistics: some View {
        let activities = filteredRecords.map { $0.activityLevel.rawValue }
        
        guard !activities.isEmpty else {
            return AnyView(Text("活動量データがありません").foregroundColor(.secondary))
        }
        
        let avgActivity = Double(activities.reduce(0, +)) / Double(activities.count)
        let latestActivity = filteredRecords.first?.activityLevel.description ?? "なし"
        
        // 活動レベルのカウント
        let lowCount = activities.filter { $0 == 1 }.count
        let normalCount = activities.filter { $0 == 2 }.count
        let highCount = activities.filter { $0 == 3 }.count
        
        return AnyView(
            VStack(spacing: 10) {
                StatsRow(label: "最新", value: latestActivity)
                StatsRow(label: "平均", value: String(format: "%.1f", avgActivity))
                StatsRow(label: "低活動", value: "\(lowCount)回 (\(Int((Double(lowCount) / Double(activities.count)) * 100))%)")
                StatsRow(label: "普通", value: "\(normalCount)回 (\(Int((Double(normalCount) / Double(activities.count)) * 100))%)")
                StatsRow(label: "活発", value: "\(highCount)回 (\(Int((Double(highCount) / Double(activities.count)) * 100))%)")
            }
        )
    }
}

struct StatsRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(.medium)
        }
    }
}

// 以下はグラフ表示のための構造体（簡易版として実装）
// 実際の実装ではSwiftChartやSwiftUIChartsなどのライブラリを使用するとより高度なグラフが実現可能

struct WeightChart: View {
    let records: [HealthRecord]
    
    var body: some View {
        // 体重のデータポイントを作成
        let dataPoints = records
            .sorted { $0.date < $1.date }
            .compactMap { record -> (date: Date, weight: Double)? in
                guard let weight = record.weight else { return nil }
                return (date: record.date, weight: weight)
            }
        
        return ChartView(
            dataPoints: dataPoints.map { $0.weight },
            dates: dataPoints.map { $0.date },
            color: .blue,
            unitName: "kg"
        )
    }
}

struct TemperatureChart: View {
    let records: [HealthRecord]
    
    var body: some View {
        // 体温のデータポイントを作成
        let dataPoints = records
            .sorted { $0.date < $1.date }
            .compactMap { record -> (date: Date, temperature: Double)? in
                guard let temperature = record.temperature else { return nil }
                return (date: record.date, temperature: temperature)
            }
        
        return ChartView(
            dataPoints: dataPoints.map { $0.temperature },
            dates: dataPoints.map { $0.date },
            color: .orange,
            unitName: "°C"
        )
    }
}

struct AppetiteChart: View {
    let records: [HealthRecord]
    
    var body: some View {
        // 食欲のデータポイントを作成
        let dataPoints = records
            .sorted { $0.date < $1.date }
            .map { (date: $0.date, appetite: Double($0.appetite.rawValue)) }
        
        return ChartView(
            dataPoints: dataPoints.map { $0.appetite },
            dates: dataPoints.map { $0.date },
            color: .green,
            unitName: "",
            minValue: 1,
            maxValue: 3
        )
    }
}

struct ActivityChart: View {
    let records: [HealthRecord]
    
    var body: some View {
        // 活動量のデータポイントを作成
        let dataPoints = records
            .sorted { $0.date < $1.date }
            .map { (date: $0.date, activity: Double($0.activityLevel.rawValue)) }
        
        return ChartView(
            dataPoints: dataPoints.map { $0.activity },
            dates: dataPoints.map { $0.date },
            color: .purple,
            unitName: "",
            minValue: 1,
            maxValue: 3
        )
    }
}

struct ChartView: View {
    let dataPoints: [Double]
    let dates: [Date]
    let color: Color
    let unitName: String
    var minValue: Double?
    var maxValue: Double?
    
    private var actualMinValue: Double {
        minValue ?? (dataPoints.min() ?? 0) * 0.9
    }
    
    private var actualMaxValue: Double {
        maxValue ?? (dataPoints.max() ?? 1) * 1.1
    }
    
    private var range: Double {
        actualMaxValue - actualMinValue
    }
    
    private func normalize(_ value: Double) -> Double {
        (value - actualMinValue) / (range > 0 ? range : 1)
    }
    
    var body: some View {
        VStack {
            if dataPoints.isEmpty {
                Text("データがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    // グラフ
                    GeometryReader { geometry in
                        ZStack(alignment: .bottomLeading) {
                            // Y軸
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1)
                                .offset(x: 0, y: 0)
                            
                            // X軸
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            // データポイントを線で結ぶ
                            Path { path in
                                guard dataPoints.count > 1 else { return }
                                
                                let step = geometry.size.width / CGFloat(dataPoints.count - 1)
                                
                                path.move(to: CGPoint(
                                    x: 0,
                                    y: geometry.size.height * (1 - CGFloat(normalize(dataPoints[0])))
                                ))
                                
                                for i in 1..<dataPoints.count {
                                    path.addLine(to: CGPoint(
                                        x: step * CGFloat(i),
                                        y: geometry.size.height * (1 - CGFloat(normalize(dataPoints[i])))
                                    ))
                                }
                            }
                            .stroke(color, lineWidth: 2)
                            
                            // データポイント
                            ForEach(0..<dataPoints.count, id: \.self) { i in
                                Circle()
                                    .fill(color)
                                    .frame(width: 6, height: 6)
                                    .position(
                                        x: geometry.size.width * (CGFloat(i) / CGFloat(dataPoints.count - 1 > 0 ? dataPoints.count - 1 : 1)),
                                        y: geometry.size.height * (1 - CGFloat(normalize(dataPoints[i])))
                                    )
                            }
                        }
                    }
                    .frame(height: 180)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    
                    // X軸ラベル
                    HStack {
                        if let firstDate = dates.first {
                            Text(formatShortDate(firstDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if dates.count > 1, let lastDate = dates.last {
                            Text(formatShortDate(lastDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}
