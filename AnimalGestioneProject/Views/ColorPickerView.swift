import SwiftUI

struct ColorPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var color: Color
    var onSave: (Color) -> Void
    
    // プリセットカラー
    private let presetColors: [[Color]] = [
        // 明るい色
        [
            Color(hex: "#FF9AA2"), // ライトピンク
            Color(hex: "#FFB7B2"), // ピーチ
            Color(hex: "#FFDAC1"), // アプリコット
            Color(hex: "#E2F0CB"), // ライトグリーン
            Color(hex: "#B5EAD7"), // ミント
        ],
        // 中間色
        [
            Color(hex: "#C7CEEA"), // ラベンダー
            Color(hex: "#FF9F1C"), // オレンジ
            Color(hex: "#2EC4B6"), // ティール
            Color(hex: "#FF6B6B"), // コーラル
            Color(hex: "#4EA8DE"), // スカイブルー
        ],
        // 濃い色
        [
            Color(hex: "#CB997E"), // タン
            Color(hex: "#A5A58D"), // セージ
            Color(hex: "#6B705C"), // オリーブ
            Color(hex: "#B7B7A4"), // カーキ
            Color(hex: "#FFE8D6"), // クリーム
        ],
        // 追加色
        [
            Color(hex: "#023E8A"), // ネイビー
            Color(hex: "#D62828"), // レッド
            Color(hex: "#1B4332"), // フォレスト
            Color(hex: "#9D4EDD"), // パープル
            Color(hex: "#647AA3"), // スレート
        ]
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 選択した色のプレビュー
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 100, height: 100)
                }
                .padding(.top, 20)
                
                // プリセットカラーグリッド
                VStack(spacing: 15) {
                    Text("プリセットカラー")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
                    ForEach(0..<presetColors.count, id: \.self) { row in
                        HStack(spacing: 15) {
                            ForEach(0..<presetColors[row].count, id: \.self) { col in
                                let presetColor = presetColors[row][col]
                                
                                Button(action: {
                                    color = presetColor
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(presetColor)
                                            .frame(width: 50, height: 50)
                                            
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 50, height: 50)
                                        
                                        if color.toHex() == presetColor.toHex() {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 3)
                                                .frame(width: 42, height: 42)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // カスタムカラーピッカー
                VStack(alignment: .leading, spacing: 15) {
                    Text("カスタムカラー")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
                    ColorPicker("色を選択", selection: $color)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("テーマ色を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(color)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct ColorPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerView(color: .constant(Color.blue), onSave: { _ in })
    }
}
