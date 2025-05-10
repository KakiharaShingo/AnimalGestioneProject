import SwiftUI

struct SplashScreen: View {
    @Binding var showSplash: Bool
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation: Double = 0
    @State private var pawOffset: CGFloat = -100
    
    // 動物アイコンの設定を取得
    @AppStorage("animalIcon") private var animalIcon = "pawprint"
    
    var body: some View {
        splashView
    }
    
    var splashView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    // メインロゴ
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 150, height: 150)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: animalIcon + ".fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.orange)
                            .rotationEffect(.degrees(rotation))
                    }
                    .scaleEffect(size)
                    .opacity(opacity)
                    
                    Text("Animal Gestione")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 10)
                        .opacity(opacity)
                    
                    Text("ペットの健康管理アプリ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(opacity)
                }
                
                Spacer()
                
                // 足跡のアニメーション
                HStack(spacing: 20) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: animalIcon + ".fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(Double(i * 5 - 10)))
                            .offset(x: pawOffset + CGFloat(i * 30))
                            .opacity(opacity)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // アニメーションを順番に実行
            withAnimation(.easeIn(duration: 1.2)) {
                self.size = 1.0
                self.opacity = 1.0
            }
            
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                rotation = 10
            }
            
            withAnimation(Animation.easeOut(duration: 1.5)) {
                pawOffset = 300
            }
            
            // 2秒後にメイン画面へ遷移
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    self.showSplash = false
                }
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen(showSplash: .constant(true))
    }
}
