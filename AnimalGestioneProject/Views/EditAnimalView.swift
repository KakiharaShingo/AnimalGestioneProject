import SwiftUI

struct EditAnimalView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var species: String
    @State private var breed: String
    @State private var gender: Animal.Gender
    @State private var birthDate: Date
    @State private var hasBirthDate: Bool
    @State private var image: UIImage?
    @State private var showImagePicker = false
    
    private var originalAnimal: Animal
    private var onSave: (Animal) -> Void
    
    init(animal: Animal, onSave: @escaping (Animal) -> Void) {
        self.originalAnimal = animal
        self.onSave = onSave
        
        _name = State(initialValue: animal.name)
        _species = State(initialValue: animal.species)
        _breed = State(initialValue: animal.breed ?? "")
        _gender = State(initialValue: animal.gender)
        _birthDate = State(initialValue: animal.birthDate ?? Date())
        _hasBirthDate = State(initialValue: animal.birthDate != nil)
        
        // 画像の読み込みは非同期で行うべきだが、簡略化のため同期的に実装
        if let imageUrl = animal.imageUrl, let data = try? Data(contentsOf: imageUrl) {
            _image = State(initialValue: UIImage(data: data))
        }
    }
    
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
            .navigationTitle("ペット情報を編集")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveAnimal()
                    }
                    .disabled(name.isEmpty || species.isEmpty)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image)
            }
        }
    }
    
    private func saveAnimal() {
        var imageUrl = originalAnimal.imageUrl
        
        if let image = image {
            // 元の画像があれば読み込み
            let originalImage: UIImage? = {
                if let url = originalAnimal.imageUrl, 
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    return image
                }
                return nil
            }()
            
            // 画像が変更された場合、新しい画像を保存
            if originalImage == nil || image != originalImage {
                if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileName = UUID().uuidString + ".jpg"
                    let fileURL = documentsDirectory.appendingPathComponent(fileName)
                    
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        try? imageData.write(to: fileURL)
                        imageUrl = fileURL
                    }
                }
            }
        }
        
        // 更新された動物情報を作成
        var updatedAnimal = originalAnimal
        updatedAnimal.name = name
        updatedAnimal.species = species
        updatedAnimal.breed = breed.isEmpty ? nil : breed
        updatedAnimal.birthDate = hasBirthDate ? birthDate : nil
        updatedAnimal.gender = gender
        updatedAnimal.imageUrl = imageUrl
        
        onSave(updatedAnimal)
        presentationMode.wrappedValue.dismiss()
    }
}