import SwiftUI

// このビューは利用されません - 削除予定
// 一時的にコンパイルエラーを回避するためにコメントアウトしています

/*
struct ColorPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var color: Color
    var onSave: (Color) -> Void
    
    // プリセットカラー
    private let presetColors: [[Color]] = [
        // 明るい色
        [
            Color(.red), // ライトピンク
            Color(.orange), // ピーチ
            Color(.yellow), // アプリコット
            Color(.green), // ライトグリーン
            Color(.mint), // ミント
        ],
        // 中間色
        [
            Color(.blue), // ラベンダー
            Color(.orange), // オレンジ
            Color(.teal), // ティール
            Color(.red), // コーラル
            Color(.blue), // スカイブルー
        ],
        // 濃い色
        [
            Color(.brown), // タン
            Color(.gray), // セージ
            Color(.gray), // オリーブ
            Color(.gray), // カーキ
            Color(.white), // クリーム
        ],
        // 追加色
        [
            Color(.blue), // ネイビー
            Color(.red), // レッド
            Color(.green), // フォレスト
            Color(.purple), // パープル
            Color(.blue), // スレート
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
                                        
                                        if color == presetColor {
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
*/
