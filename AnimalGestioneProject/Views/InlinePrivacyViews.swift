import SwiftUI

// 箇条書き用のヘルパービュー
struct BulletPointText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .padding(.trailing, 5)
            Text(text)
            Spacer()
        }
        .padding(.leading)
    }
}

