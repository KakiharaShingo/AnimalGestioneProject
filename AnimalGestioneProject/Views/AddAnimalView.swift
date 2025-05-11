import SwiftUI

struct AddAnimalView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataStore: CoreDataStore
    @State private var showPremiumPurchase = false
    @State private var showLimitAlert = false
    
    @State private var name = ""
    @State private var species = ""
    @State private var breed = ""
    @State private var gender = Animal.Gender.unknown
    @State private var birthDate = Date()
    @State private var showBirthDatePicker = false
    @State private var hasBirthDate = false
    @State private var image: UIImage?
    @State private var showImagePicker = false
    
    // 購入管理インスタンス
    private let purchaseManager = InAppPurchaseManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("名前", text: $name)
                    TextField("種類（例：猫、犬）", text: $species)
                    TextField("品種（任意）", text: $breed)
                    
                    Picker("性別", selection: $gender) {
                        ForEach(Animal.Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
                    Toggle("誕生日を設定", isOn: $hasBirthDate)
                    
                    if hasBirthDate {
                        DatePicker(
                            "誕生日",
                            selection: $birthDate,
                            displayedComponents: .date
                        )
                    }
                }
                
                Section(header: Text("画像")) {
                    if let image = image {
                        HStack {
                            Spacer()
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Text(image == nil ? "画像を選択" : "画像を変更")
                    }
                }
            }
            .navigationTitle("ペットを追加")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        // 登録制限のチェック
                        if !purchaseManager.canRegisterMoreAnimals(currentCount: dataStore.animals.count) {
                            showLimitAlert = true
                        } else {
                            saveAnimal()
                        }
                    }
                    .disabled(name.isEmpty || species.isEmpty)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image)
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
    }
    
    private func saveAnimal() {
        var imageUrl: URL?
        
        if let image = image {
            // 画像を保存してURLを取得（実際のアプリではより堅牢なファイル管理を実装）
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileName = UUID().uuidString + ".jpg"
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    try? imageData.write(to: fileURL)
                    imageUrl = fileURL
                }
            }
        }
        
        let animal = Animal(
            name: name,
            species: species,
            breed: breed.isEmpty ? nil : breed,
            birthDate: hasBirthDate ? birthDate : nil,
            gender: gender,
            imageUrl: imageUrl
        )
        
        dataStore.addAnimal(animal)
        presentationMode.wrappedValue.dismiss()
    }
}