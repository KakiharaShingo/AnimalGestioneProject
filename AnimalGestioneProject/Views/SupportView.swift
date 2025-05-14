import SwiftUI

// FAQデータモデル
struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// ガイドアイテムデータモデル
struct GuideItem: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let description: String
}

// ガイドセクションデータモデル
struct GuideSection: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let image: String
}

struct SupportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    @State private var showingContactForm = false
    @State private var showingGuide = false
    @State private var selectedGuideItem: GuideItem? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // タブセレクター
                HStack(spacing: 0) {
                    ForEach(0..<3) { index in
                        Button(action: {
                            withAnimation {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: tabIcon(for: index))
                                    .font(.system(size: 22))
                                
                                Text(tabTitle(for: index))
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedTab == index ? Color.blue.opacity(0.1) : Color.clear)
                            .foregroundColor(selectedTab == index ? .blue : .gray)
                        }
                        
                        if index < 2 {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.systemGray5)),
                    alignment: .bottom
                )
                
                // コンテンツ表示
                Group {
                    switch selectedTab {
                    case 0:
                        FAQListView()
                    case 1:
                        GuidesListView(showingGuide: $showingGuide, selectedGuideItem: $selectedGuideItem)
                    case 2:
                        ContactSupportView(showingContactForm: $showingContactForm)
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationBarTitle("サポート", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("閉じる")
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingContactForm) {
            ContactFormView(isPresented: $showingContactForm)
        }
        .sheet(item: $selectedGuideItem) { guideItem in
            NavigationView {
                GuideDetailView(guideItem: guideItem)
                    .navigationBarItems(leading: Button("閉じる") {
                        selectedGuideItem = nil
                    })
                    .navigationBarTitle(guideItem.title, displayMode: .inline)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "よくある質問"
        case 1: return "使い方ガイド"
        case 2: return "お問い合わせ"
        default: return ""
        }
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "questionmark.circle"
        case 1: return "book"
        case 2: return "envelope"
        default: return ""
        }
    }
}
