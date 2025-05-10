import SwiftUI

struct AppIconGenerator: View {
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)), Color(#colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1))]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 肉球メインアイコン
            VStack {
                Spacer()
                
                Image(systemName: "pawprint.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 400, height: 400)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                
                Spacer()
                
                // 動物シルエット
                HStack(spacing: 40) {
                    Image(systemName: "cat.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Image(systemName: "dog.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Image(systemName: "hare.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100)
                        .foregroundColor(.white.opacity(0.8))
                }
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Spacer()
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

struct AppIconPreview: PreviewProvider {
    static var previews: some View {
        AppIconGenerator()
    }
}
