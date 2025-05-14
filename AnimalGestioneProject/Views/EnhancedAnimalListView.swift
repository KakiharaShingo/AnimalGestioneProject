import SwiftUI

struct EnhancedAnimalListView: View {
    @EnvironmentObject var dataStore: CoreDataStore
    @Binding var selectedDate: Date
    @State private var showingAddAnimal = false
    @State private var showPremiumPurchase = false
    @State private var showLimitAlert = false
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .grid
    @State private var selectedAnimalId: UUID? = nil
    @State private var showHealthRecord = false
    @State private var refreshID = UUID() // 再描画用のID
    
    // 購入管理インスタンス
    private let purchaseManager = InAppPurchaseManager.shared
    
    // 動物アイコンの設定を取得
    @AppStorage("animalIcon") private var animalIcon = "pawprint"
    
    enum ViewMode {
        case grid, list
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                // 動物詳細画面へのナビゲーションリンク（詳細画面に遷移する条件を改善）
                if let animalId = selectedAnimalId, let animal = dataStore.animals.first(where: { $0.id == animalId }), !showHealthRecord {
                    NavigationLink(destination: AnimalDetailView(animal: animal), isActive: Binding<Bool>(get: { selectedAnimalId != nil && !showHealthRecord }, set: { if !$0 { selectedAnimalId = nil } })) {
                        EmptyView()
                    }
                }
                
                // 健康記録画面へのナビゲーションリンク（非表示）
                if let animalId = selectedAnimalId, showHealthRecord {
                    NavigationLink(destination: AnimalGestioneProject.HealthRecordView(animalId: animalId, isEmbedded: false), isActive: $showHealthRecord) {
                        EmptyView()
                    }
                }
                
                VStack(spacing: 0) {
                    // 検索バーとビューモード切り替え
                    HStack {
                        SearchBar(text: $searchText)
                        
                        Button(action: {
                            withAnimation {
                                viewMode = viewMode == .grid ? .list : .grid
                            }
                        }) {
                            Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // フィルター結果
                    let filteredAnimals = searchText.isEmpty ? dataStore.animals : dataStore.animals.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.species.localizedCaseInsensitiveContains(searchText) }
                    
                    // ペット一覧
                    if filteredAnimals.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: animalIcon + ".circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(Color.gray.opacity(0.5))
                            
                            Text("ペットが登録されていません")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("ペットを追加して、健康管理を始めましょう")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                addAnimalWithCheck()
                            }) {
                                Text("ペットを追加")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 30)
                                    .background(Color.orange)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 10)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            if viewMode == .grid {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                                    ForEach(filteredAnimals) { animal in
                                        NavigationLink(destination: AnimalDetailView(animal: animal)) {
                                            EnhancedAnimalCard(animal: animal)
                                                .id(refreshID)  // 再描画のためのIDを追加
                                        }
                                    }
                                }
                                .padding()
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredAnimals) { animal in
                                        NavigationLink(destination: AnimalDetailView(animal: animal)) {
                                            EnhancedAnimalRow(animal: animal)
                                                .id(refreshID)  // 再描画のためのIDを追加
                                        }
                                    }
                                }
                                .padding()
                            }
                            
                            // プレミアム機能の案内（無料ユーザーかつ上限数に達した場合）
                            if !purchaseManager.hasRemoveAdsPurchased() && 
                               dataStore.animals.count >= InAppPurchaseManager.freeUserAnimalLimit {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                        Text("プレミアム機能")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Text("プレミアム版にアップグレードすると、\(InAppPurchaseManager.freeUserAnimalLimit)匹以上のペットを登録できるようになります。")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Button(action: {
                                        showPremiumPurchase = true
                                    }) {
                                        Text("プレミアムにアップグレード")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 20)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                    }
                                    .padding(.top, 8)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("マイペット")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addAnimalWithCheck()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showingAddAnimal) {
                AddAnimalView()
            }
            .sheet(isPresented: $showPremiumPurchase) {
                PremiumPurchaseView()
            }
            .alert(isPresented: $showLimitAlert) {
                Alert(
                    title: Text("登録数制限"),
                    message: Text("無料版では\(InAppPurchaseManager.freeUserAnimalLimit)匹までしか登録できません。プレミアム版にアップグレードして制限を解除しますか？"),
                    primaryButton: .default(Text("アップグレード")) {
                        showPremiumPurchase = true
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            setupNotificationObservers()
        }
    }
    
    // 動物追加時に登録上限をチェックするメソッド
    private func addAnimalWithCheck() {
        if !purchaseManager.canRegisterMoreAnimals(currentCount: dataStore.animals.count) {
            showLimitAlert = true
        } else {
            showingAddAnimal = true
        }
    }
    
    private func setupNotificationObservers() {
        // 動物詳細画面を開く通知の監視
        NotificationCenter.default.addObserver(forName: NSNotification.Name("OpenAnimalDetail"), object: nil, queue: .main) { notification in
            if let animalId = notification.object as? UUID {
                // 先に健康記録の状態をリセット
                self.showHealthRecord = false
                
                // 新しいディスパッチで元の処理が完了した後に実行
                DispatchQueue.main.async {
                    self.selectedAnimalId = animalId
                }
            }
        }
        
        // 健康記録画面を開く通知の監視
        NotificationCenter.default.addObserver(forName: NSNotification.Name("OpenHealthRecord"), object: nil, queue: .main) { notification in
            if let animalId = notification.object as? UUID {
                // 先に動物IDを設定してから健康記録を開く
                self.selectedAnimalId = animalId
                
                // 少し遅延させて確実に健康記録画面を開く
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showHealthRecord = true
                }
            }
        }
        
        // 直接健康記録画面を開く通知の監視
        NotificationCenter.default.addObserver(forName: NSNotification.Name("DirectOpenHealthRecord"), object: nil, queue: .main) { notification in
            if let animalId = notification.object as? UUID {
                // モーダルで直接健康記録画面を表示
                self.selectedAnimalId = animalId
                self.showDirectHealthRecord(animalId: animalId)
            }
        }
        
        // 動物の色変更通知の監視
        NotificationCenter.default.addObserver(forName: NSNotification.Name("AnimalColorChanged"), object: nil, queue: .main) { _ in
            // IDを更新してビューの再描画をトリガー
            self.refreshID = UUID()
        }
    }
    
    // 直接健康記録画面を表示するメソッド
    private func showDirectHealthRecord(animalId: UUID) {
        // 直接健康記録画面を表示する通知を送信
        // ここでは何もしない - この通知はEnhancedContentViewで処理される
    }
}

struct EnhancedAnimalCard: View {
    let animal: Animal
    @EnvironmentObject var dataStore: CoreDataStore
    @AppStorage("animalIcon") private var animalIcon = "pawprint"
    
    var body: some View {
        VStack(spacing: 8) {
            // ヘッダー部分（画像と名前）
            ZStack(alignment: .bottom) {
                // 背景色
                Rectangle()
                    .fill(animal.color.opacity(0.15))
                    .frame(height: 120)
                    .cornerRadius(12, corners: [.topLeft, .topRight])
                
                // 画像
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 84, height: 84)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    if let imageUrl = animal.imageUrl, let uiImage = loadImage(from: imageUrl) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 76, height: 76)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: animalIcon + ".fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(animal.color)
                    }
                }
                .offset(y: 42)
            }
            
            // 名前と詳細部分
            VStack(spacing: 6) {
                Spacer().frame(height: 38)
                
                Text(animal.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    Text(animal.species)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(animal.gender.rawValue)
                        .font(.subheadline)
                        .foregroundColor(genderColor(animal.gender))
                        .lineLimit(1)
                }
                
                if let birthDate = animal.birthDate {
                    Text(formatAge(from: birthDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                Spacer().frame(height: 8)
                
                // 生理周期予測がある場合
                if let predictionDate = dataStore.predictNextCycle(animalId: animal.id) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(daysUntilColor(predictionDate))
                        
                        Text(daysUntil(predictionDate))
                            .font(.caption)
                            .foregroundColor(daysUntilColor(predictionDate))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(daysUntilColor(predictionDate).opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
    
    private func formatAge(from birthDate: Date) -> String {
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
    
    private func daysUntil(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        
        guard let days = components.day else { return "" }
        
        if days == 0 {
            return "今日生理予測"
        } else if days < 0 {
            return "\(abs(days))日前に予測"
        } else {
            return "あと\(days)日で生理予測"
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
            return .green
        } else {
            return .blue
        }
    }
    
    private func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

struct EnhancedAnimalRow: View {
    let animal: Animal
    @EnvironmentObject var dataStore: CoreDataStore
    @AppStorage("animalIcon") private var animalIcon = "pawprint"
    
    var body: some View {
        HStack(spacing: 15) {
            // 画像
            ZStack {
                Circle()
                    .fill(animal.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                if let imageUrl = animal.imageUrl, let uiImage = loadImage(from: imageUrl) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                } else {
                    Image(systemName: animalIcon + ".fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(animal.color)
                }
            }
            
            // 情報
            VStack(alignment: .leading, spacing: 4) {
                Text(animal.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(animal.species)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(animal.gender.rawValue)
                        .font(.subheadline)
                        .foregroundColor(genderColor(animal.gender))
                }
                
                if let birthDate = animal.birthDate {
                    Text(formatAge(from: birthDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 生理周期予測がある場合
            if let predictionDate = dataStore.predictNextCycle(animalId: animal.id) {
                VStack(alignment: .center, spacing: 4) {
                    Text(daysUntil(predictionDate))
                        .font(.caption)
                        .foregroundColor(daysUntilColor(predictionDate))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(daysUntilColor(predictionDate).opacity(0.1))
                        .cornerRadius(10)
                    
                    Text(formatShortDate(predictionDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.gray.opacity(0.5))
                .padding(.leading, 5)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
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
    
    private func formatAge(from birthDate: Date) -> String {
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
    
    private func formatShortDate(_ date: Date) -> String {
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
            return .green
        } else {
            return .blue
        }
    }
    
    private func loadImage(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

// 丸めた角の拡張
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}