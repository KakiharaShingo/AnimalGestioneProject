import SwiftUI

// よくある質問ビュー
struct FAQListView: View {
    // FAQデータ
    let faqs = [
        FAQ(question: "アプリの基本機能は何ですか？", 
            answer: "AnimalGestioneProjectは、ペットの健康記録を管理するためのアプリです。ペットの基本情報、健康状態、医療記録、生理周期などを追跡・管理することができます。すべてのデータはお使いのデバイスに保存され、予定の通知機能も備えています。"),
        
        FAQ(question: "複数のペットを登録できますか？", 
            answer: "無料版では最大3匹までのペットを登録できます。プレミアム版にアップグレードすると、登録制限が解除され、無制限にペットを登録できます。それぞれのペットに個別の健康記録、ワクチン接種履歴、健康診断予定などを管理できます。"),
        
        FAQ(question: "プレミアム版の特典は何ですか？", 
            answer: "プレミアム版では以下の特典があります：\n・広告の非表示\n・ペット登録数の制限解除（3匹以上登録可能）"),
        
        FAQ(question: "データのバックアップ方法は？", 
            answer: "設定画面から「データのバックアップと復元」を選択すると、データをCSV形式でエクスポートすることができます。バックアップデータはメールやクラウドサービスなどを通じて保存しておくことができます。"),
        
        FAQ(question: "通知設定はどこで変更できますか？", 
            answer: "設定画面の「通知」セクションから、通知のオン/オフ、リマインダー時間、通知種類などを詳細に設定することができます。"),
        
        FAQ(question: "アプリ内の情報は他の人と共有されますか？", 
            answer: "いいえ、アプリ内に入力されたすべての情報はお使いのデバイス内に保存され、あなたの許可なく外部に共有されることはありません。詳しくはプライバシーポリシーをご覧ください。"),
        
        FAQ(question: "ペットの写真を追加できますか？", 
            answer: "はい、各ペットのプロフィールに写真を追加できます。「ペット編集」画面でカメラボタンをタップして、カメラロールから選択するか、新しい写真を撮影してください。"),
        
        FAQ(question: "アプリの言語を変更できますか？", 
            answer: "アプリはデバイスの言語設定に従います。言語を変更するには、デバイスの設定から言語を変更してください。"),
        
        FAQ(question: "ペットを削除するとデータはどうなりますか？", 
            answer: "ペットを削除すると、そのペットに関連するすべてのデータ（健康記録、予定、写真など）も完全に削除されます。この操作は元に戻せないので、削除前にデータのバックアップをおすすめします。"),
        
        FAQ(question: "技術的な問題が発生した場合はどうすればよいですか？", 
            answer: "「お問い合わせ」タブから問題の詳細を送信いただければ、サポートチームが対応いたします。また、アプリを再起動するか、デバイスを再起動すると解決する場合もあります。")
    ]
    
    var body: some View {
        List {
            ForEach(faqs) { faq in
                FAQItemView(faq: faq)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// FAQ項目ビュー
struct FAQItemView: View {
    let faq: FAQ
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(faq.question)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            
            if isExpanded {
                Text(faq.answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
    }
}

// 使い方ガイドリストビュー
struct GuidesListView: View {
    @Binding var showingGuide: Bool
    @Binding var selectedGuideItem: GuideItem?
    
    // ガイドデータ
    let guideItems = [
        GuideItem(id: "pets", title: "ペット管理", icon: "pawprint.fill", color: .orange, 
                  description: "ペットの追加、編集、管理方法について学びます。"),
        
        GuideItem(id: "health", title: "健康記録", icon: "heart.text.square.fill", color: .red, 
                  description: "健康状態の記録と分析方法について学びます。"),
        
        GuideItem(id: "calendar", title: "カレンダー機能", icon: "calendar", color: .blue, 
                  description: "予定管理とリマインダーの設定方法について学びます。"),
        
        GuideItem(id: "cycle", title: "生理周期管理", icon: "drop.fill", color: .pink, 
                  description: "メスの動物の生理周期を追跡する方法について学びます。"),
        
        GuideItem(id: "vaccine", title: "ワクチン管理", icon: "syringe", color: .green, 
                  description: "ワクチン接種履歴と予定管理方法について学びます。"),
        
        GuideItem(id: "grooming", title: "グルーミング記録", icon: "scissors", color: .purple, 
                  description: "トリミングやグルーミング履歴の管理方法について学びます。"),
        
        GuideItem(id: "export", title: "データエクスポート", icon: "square.and.arrow.up", color: .gray, 
                  description: "データのバックアップと共有方法について学びます。"),
        
        GuideItem(id: "premium", title: "プレミアム機能", icon: "crown.fill", color: .yellow, 
                  description: "プレミアム版の特典と購入方法について学びます。")
    ]
    
    var body: some View {
        List {
            ForEach(guideItems) { item in
                Button(action: {
                    selectedGuideItem = item
                    showingGuide = true
                }) {
                    HStack(spacing: 15) {
                        Image(systemName: item.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(item.color)
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.headline)
                            
                            Text(item.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// ガイドセクションビュー
struct GuideSectionView: View {
    let section: GuideSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: section.image)
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(section.title)
                    .font(.headline)
            }
            
            Text(section.content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 30)
        }
        .padding(.vertical, 10)
    }
}
