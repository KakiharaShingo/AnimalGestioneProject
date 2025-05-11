import SwiftUI

// ガイド詳細ビュー
struct GuideDetailView: View {
    let guideItem: GuideItem
    
    // 各ガイドの詳細コンテンツ
    var guideContent: [GuideSection] {
        switch guideItem.id {
        case "pets":
            return [
                GuideSection(title: "ペットの追加方法", content: "1. ホーム画面またはペット一覧画面の「+」ボタンをタップします。\n2. ペットの名前、種類、品種、誕生日、性別などの基本情報を入力します。\n3. 必要に応じて写真を追加します。\n4. 「保存」をタップして完了です。", image: "plus.circle"),
                GuideSection(title: "ペット情報の編集", content: "1. ペット一覧からペットを選択して詳細画面を開きます。\n2. 「編集」ボタンをタップします。\n3. 情報を変更して「保存」をタップします。", image: "pencil.circle"),
                GuideSection(title: "ペットの削除", content: "1. ペット一覧からペットをスワイプするか、詳細画面の「編集」から「削除」を選択します。\n2. 確認ダイアログで「削除」をタップします。\n\n注意：削除したデータは復元できません。", image: "trash.circle"),
                GuideSection(title: "ペットプロフィールのカスタマイズ", content: "ペットごとに独自のカラーを設定できます。詳細画面の「カラー設定」から選択してください。カラーはカレンダーやリスト表示で使用されます。", image: "paintpalette")
            ]
            
        case "health":
            return [
                GuideSection(title: "健康記録の追加", content: "1. ペット詳細画面から「健康記録」タブを選択します。\n2. 「+」ボタンをタップして新しい記録を追加します。\n3. 日付、体重、体温、食欲、活動レベルなどを入力します。\n4. 「保存」をタップして完了です。", image: "heart.text.square"),
                GuideSection(title: "健康記録の閲覧", content: "ペット詳細画面の「健康記録」タブでは、時系列で健康記録を確認できます。グラフ表示に切り替えると、体重の推移などを視覚的に確認できます。", image: "list.bullet.rectangle"),
                GuideSection(title: "健康データのグラフ表示", content: "健康状態の推移をグラフで確認できます。体重の変化などを視覚的に確認して、ペットの健康管理に役立てましょう。", image: "chart.bar.xaxis"),
                GuideSection(title: "健康記録のエクスポート", content: "特定のペットまたはすべてのペットの健康記録をCSVファイルとしてエクスポートできます。設定画面の「データのCSVエクスポート」から行ってください。", image: "arrow.up.doc")
            ]
            
        case "calendar":
            return [
                GuideSection(title: "カレンダーの基本操作", content: "カレンダー画面では、すべてのペットの予定が表示されます。日付をタップすると、その日のイベント詳細が表示されます。月表示と週表示を切り替えることもできます。", image: "calendar"),
                GuideSection(title: "予定の追加方法", content: "1. カレンダー画面で日付をタップして「+」ボタンを押すか、各記録画面から予定を設定します。\n2. ワクチン接種、健康診断、グルーミングなどのイベントタイプを選択します。\n3. 詳細を入力して「保存」します。", image: "calendar.badge.plus"),
                GuideSection(title: "繰り返し予定の設定", content: "ワクチン接種や健康診断などの定期的な予定は、間隔を設定して自動的に次回の予定を追加できます。「繰り返し間隔」を指定してください。", image: "arrow.clockwise"),
                GuideSection(title: "通知設定", content: "各予定に対して、事前通知を設定できます。「通知時間」で当日または数日前に通知を受け取るよう指定できます。アプリの通知設定がオンになっていることを確認してください。", image: "bell")
            ]
            
        case "cycle":
            return [
                GuideSection(title: "生理周期の記録", content: "1. ペット詳細画面から「生理周期」タブを選択します。\n2. 「+」ボタンをタップして新しい周期を追加します。\n3. 開始日、終了日（任意）、強度を入力します。\n4. 「保存」をタップして完了です。", image: "drop"),
                GuideSection(title: "周期予測機能", content: "過去の記録から次回の周期を予測します。少なくとも2回の周期を記録すると、予測が表示されます。予測日はカレンダーに薄い色で表示されます。", image: "calendar.circle"),
                GuideSection(title: "アラート設定", content: "生理周期の開始前にアラートを受け取ることができます。ペット詳細画面の「生理周期」タブで「予測アラート」をオンにしてください。", image: "bell.badge"),
                GuideSection(title: "周期カレンダー", content: "カレンダー画面では、生理周期が色付きで表示されます。強度によって色の濃さが変わります。予測は薄い色で表示されます。", image: "calendar.day")
            ]
            
        case "vaccine":
            return [
                GuideSection(title: "ワクチン記録の追加", content: "1. ペット詳細画面から「医療」タブを選択し、「ワクチン」を選びます。\n2. 「+」ボタンをタップして新しい記録を追加します。\n3. ワクチン名、接種日、次回予定日などを入力します。\n4. 「保存」をタップして完了です。", image: "syringe"),
                GuideSection(title: "次回接種日の設定", content: "ワクチン記録を追加する際に「次回予定日」を入力するか、「間隔」を指定すると自動的に次回接種日が計算されます。カレンダーにイベントとして表示されます。", image: "calendar.badge.clock"),
                GuideSection(title: "ワクチン接種スケジュール", content: "ホーム画面の「近日中の予定」セクションや、カレンダーで次回のワクチン接種予定を確認できます。必要に応じて日付を変更することもできます。", image: "list.bullet.clipboard")
            ]
            
        case "grooming":
            return [
                GuideSection(title: "グルーミング記録の追加", content: "1. ペット詳細画面から「ケア」タブを選択し、「グルーミング」を選びます。\n2. 「+」ボタンをタップして新しい記録を追加します。\n3. 日付、グルーミングタイプ、次回予定日などを入力します。\n4. 「保存」をタップして完了です。", image: "scissors"),
                GuideSection(title: "グルーミングタイプ", content: "シャンプー、トリミング、爪切り、歯磨きなど、さまざまなグルーミングタイプから選択できます。カスタムタイプを作成することもできます。", image: "list.bullet"),
                GuideSection(title: "定期的なリマインダー", content: "グルーミングの種類ごとに異なる間隔を設定できます。例えば、トリミングは2ヶ月ごと、爪切りは2週間ごとなど柔軟に設定可能です。", image: "timer"),
                GuideSection(title: "グルーミング履歴", content: "過去のグルーミング記録を時系列で確認できます。各記録をタップすると詳細を表示します。不要な記録は左にスワイプして削除できます。", image: "clock")
            ]
            
        case "export":
            return [
                GuideSection(title: "データエクスポートの基本", content: "設定画面から「データのCSVエクスポート」を選択すると、アプリのデータをCSV形式でエクスポートできます。ペットごと、または全ペットのデータを選択できます。", image: "square.and.arrow.up"),
                GuideSection(title: "データのバックアップ", content: "定期的にデータをバックアップすることをお勧めします。設定画面の「データのバックアップと復元」からバックアップファイルを作成し、iCloudやその他のクラウドサービスに保存できます。", image: "externaldrive"),
                GuideSection(title: "データの復元", content: "バックアップからデータを復元するには、設定画面の「データのバックアップと復元」から「復元」を選び、バックアップファイルを選択します。注意：現在のデータは上書きされます。", image: "arrow.clockwise"),
                GuideSection(title: "CSVファイルの活用", content: "エクスポートしたCSVファイルは、Excel、Numbersなどの表計算ソフトで開くことができます。健康データの分析や印刷用資料の作成に役立ちます。", image: "doc.text.magnifyingglass")
            ]
            
        case "premium":
            return [
                GuideSection(title: "プレミアム機能の概要", content: "プレミアム版では以下の特典が利用できます：\n・広告の非表示\n・ペット登録数の制限解除（3匹以上登録可能）", image: "crown"),
                GuideSection(title: "プレミアム購入方法", content: "1. 設定画面から「広告を非表示にする」をタップします。\n2. 表示される「プレミアムにアップグレード」画面で「購入」をタップします。\n3. Apple IDでの認証後、購入が完了します。", image: "bag"),
                GuideSection(title: "購入の復元", content: "デバイスを変更した場合などは、設定画面の「プレミアムにアップグレード」から「購入を復元」をタップしてください。Apple IDに紐づいた購入履歴が復元されます。", image: "arrow.triangle.2.circlepath")
            ]
            
        default:
            return []
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // ヘッダー
                HStack {
                    Image(systemName: guideItem.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(guideItem.color)
                        .cornerRadius(15)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(guideItem.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(guideItem.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 5)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // ガイドコンテンツ
                ForEach(guideContent) { section in
                    GuideSectionView(section: section)
                        .padding(.horizontal)
                }
                
                // サポートリンク
                VStack(alignment: .center, spacing: 10) {
                    Text("さらに詳しい情報が必要ですか？")
                        .font(.headline)
                    
                    Button(action: {
                        // お問い合わせフォームを表示する処理を追加
                    }) {
                        Text("サポートに問い合わせる")
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.vertical)
        }
    }
}
