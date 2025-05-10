import SwiftUI
import UserNotifications

struct NotificationsListView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if notificationManager.authorizationStatus != .authorized {
                    // 通知が許可されていない場合の表示
                    NotificationsNotEnabledView()
                } else if notificationManager.deliveredNotifications.isEmpty && notificationManager.pendingNotifications.isEmpty {
                    // 通知がない場合の表示
                    EmptyNotificationsView()
                } else {
                    // 通知の一覧を表示
                    List {
                        // 配信済み通知セクション
                        if !notificationManager.deliveredNotifications.isEmpty {
                            Section(header: Text("新着通知")) {
                                ForEach(notificationManager.deliveredNotifications, id: \.request.identifier) { notification in
                                    NotificationRow(notification: notification, isDelivered: true)
                                        .swipeActions {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    notificationManager.removeDeliveredNotification(withIdentifier: notification.request.identifier)
                                                }
                                            } label: {
                                                Label("削除", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            
                            Button("すべての通知を既読にする") {
                                withAnimation {
                                    notificationManager.removeAllDeliveredNotifications()
                                }
                            }
                            .foregroundColor(.red)
                        }
                        
                        // 保留中の通知セクション
                        if !notificationManager.pendingNotifications.isEmpty {
                            Section(header: Text("予定通知")) {
                                ForEach(notificationManager.pendingNotifications, id: \.identifier) { request in
                                    NotificationRequestRow(request: request)
                                        .swipeActions {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    notificationManager.cancelPendingNotification(withIdentifier: request.identifier)
                                                }
                                            } label: {
                                                Label("キャンセル", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .refreshable {
                        notificationManager.refreshNotificationLists()
                    }
                }
            }
            .navigationTitle("通知")
            .navigationBarItems(leading: Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        notificationManager.refreshNotificationLists()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                notificationManager.checkAuthorization()
                notificationManager.refreshNotificationLists()
            }
        }
    }
}

// 通知行のコンポーネント
struct NotificationRow: View {
    let notification: UNNotification
    let isDelivered: Bool
    
    private var content: UNNotificationContent {
        notification.request.content
    }
    
    private var notificationDate: Date? {
        if let trigger = notification.request.trigger as? UNCalendarNotificationTrigger,
           let nextTriggerDate = trigger.nextTriggerDate() {
            return nextTriggerDate
        }
        return notification.date
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: iconForCategory(content.categoryIdentifier))
                    .foregroundColor(colorForCategory(content.categoryIdentifier))
                    .font(.title3)
                    .frame(width: 30)
                
                Text(content.title)
                    .font(.headline)
                
                Spacer()
            }
            
            Text(content.body)
                .font(.body)
                .lineLimit(2)
                .foregroundColor(.secondary)
                .padding(.leading, 36)
            
            if let date = notificationDate {
                Text(dateFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 36)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "PHYSIOLOGICAL":
            return "drop.fill"
        case "CHECKUP":
            return "heart.text.square.fill"
        case "VACCINE":
            return "syringe.fill"
        default:
            return "bell.fill"
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "PHYSIOLOGICAL":
            return .red
        case "CHECKUP":
            return .blue
        case "VACCINE":
            return .green
        default:
            return .orange
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// 保留中の通知行のコンポーネント
struct NotificationRequestRow: View {
    let request: UNNotificationRequest
    
    private var content: UNNotificationContent {
        request.content
    }
    
    private var triggerDate: Date? {
        if let trigger = request.trigger as? UNCalendarNotificationTrigger,
           let nextTriggerDate = trigger.nextTriggerDate() {
            return nextTriggerDate
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: iconForCategory(content.categoryIdentifier))
                    .foregroundColor(colorForCategory(content.categoryIdentifier))
                    .font(.title3)
                    .frame(width: 30)
                
                Text(content.title)
                    .font(.headline)
                
                Spacer()
            }
            
            Text(content.body)
                .font(.body)
                .lineLimit(2)
                .foregroundColor(.secondary)
                .padding(.leading, 36)
            
            if let date = triggerDate {
                Text("予定: \(dateFormatter.string(from: date))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 36)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "PHYSIOLOGICAL":
            return "drop.fill"
        case "CHECKUP":
            return "heart.text.square.fill"
        case "VACCINE":
            return "syringe.fill"
        default:
            return "bell.badge.fill"
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "PHYSIOLOGICAL":
            return .red
        case "CHECKUP":
            return .blue
        case "VACCINE":
            return .green
        default:
            return .orange
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// 通知がない場合のビュー
struct EmptyNotificationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding()
            
            Text("通知はありません")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text("通知が届くと、ここに表示されます。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
        }
    }
}

// 通知が許可されていない場合のビュー
struct NotificationsNotEnabledView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .padding()
            
            Text("通知が許可されていません")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text("アプリの通知を受け取るには、設定から通知を許可してください。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button(action: {
                notificationManager.requestAuthorization()
            }) {
                Text("通知を許可する")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
            
            Button(action: {
                // システム設定アプリに遷移するURL
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("設定アプリを開く")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct NotificationsListView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsListView()
    }
}
