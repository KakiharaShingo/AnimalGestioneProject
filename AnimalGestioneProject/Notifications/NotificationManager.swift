import Foundation
import UserNotifications
import SwiftUI

/// 通知管理を担当するシングルトンクラス
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var pendingNotifications: [UNNotificationRequest] = []
    @Published var deliveredNotifications: [UNNotification] = []
    @Published var notificationsEnabled: Bool = false
    
    // 通知の権限状態
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // 通知センター
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        
        // 通知センターのデリゲートを設定
        notificationCenter.delegate = self
        
        // 現在の認証状態を取得
        checkAuthorization()
    }
    
    // 通知の許可状態を確認
    func checkAuthorization() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.notificationsEnabled = settings.authorizationStatus == .authorized
                
                // 許可されている場合は保留中・配信済みの通知を取得
                if settings.authorizationStatus == .authorized {
                    self?.refreshNotificationLists()
                }
            }
        }
    }
    
    // 通知の許可をリクエスト
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.checkAuthorization() // 認証状態を更新
                completion(granted)
            }
            
            if let error = error {
                print("通知許可リクエストエラー: \(error.localizedDescription)")
            }
        }
    }
    
    // 保留中と配信済みの通知リストを更新
    func refreshNotificationLists() {
        // 保留中の通知を取得
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.pendingNotifications = requests
            }
        }
        
        // 配信済みの通知を取得
        notificationCenter.getDeliveredNotifications { [weak self] notifications in
            DispatchQueue.main.async {
                self?.deliveredNotifications = notifications
            }
        }
    }
    
    // 特定の通知を削除
    func removeDeliveredNotification(withIdentifier identifier: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        refreshNotificationLists()
    }
    
    // すべての配信済み通知を削除
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        refreshNotificationLists()
    }
    
    // 特定の保留中の通知をキャンセル
    func cancelPendingNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        refreshNotificationLists()
    }
    
    // すべての保留中の通知をキャンセル
    func cancelAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        refreshNotificationLists()
    }
    
    // 予定イベントの通知をスケジュール
    func scheduleEventNotification(title: String, body: String, date: Date, identifier: String? = nil, categoryIdentifier: String = "EVENT", userData: [String: Any]? = nil) {
        
        // 通知が許可されていない場合は何もしない
        guard authorizationStatus == .authorized else {
            print("通知が許可されていません")
            return
        }
        
        // 通知のコンテンツを設定
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = categoryIdentifier
        
        // ユーザーデータがあれば追加
        if let userData = userData {
            let userInfo = userData.reduce(into: [String: String]()) { (result, item) in
                result[item.key] = "\(item.value)"
            }
            content.userInfo = userInfo
        }
        
        // 通知のトリガーを設定（指定日時）
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // 通知リクエストを作成
        let requestID = identifier ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        
        // 通知をスケジュール
        notificationCenter.add(request) { error in
            if let error = error {
                print("通知スケジュールエラー: \(error.localizedDescription)")
            } else {
                print("通知がスケジュールされました: ID = \(requestID), 日時 = \(date)")
                self.refreshNotificationLists()
            }
        }
    }
    
    // 生理周期の通知をスケジュール
    func schedulePhysiologicalCycleNotification(animalName: String, predictedDate: Date) {
        let title = "\(animalName)の生理予測"
        let body = "明日から生理が始まる可能性があります。事前に準備しておきましょう。"
        
        // 生理開始の1日前に通知
        let notificationDate = Calendar.current.date(byAdding: .day, value: -1, to: predictedDate) ?? predictedDate
        
        // 通知をスケジュール
        scheduleEventNotification(
            title: title,
            body: body,
            date: notificationDate,
            identifier: "physiological-\(animalName)-\(predictedDate.timeIntervalSince1970)",
            categoryIdentifier: "PHYSIOLOGICAL",
            userData: ["animalName": animalName, "predictedDate": predictedDate.timeIntervalSince1970]
        )
    }
    
    // 健康診断リマインダーの通知をスケジュール
    func scheduleHealthCheckupReminder(animalName: String, checkupDate: Date) {
        let title = "\(animalName)の健康診断"
        let body = "明日は\(animalName)の健康診断の予定です。"
        
        // 前日に通知
        let notificationDate = Calendar.current.date(byAdding: .day, value: -1, to: checkupDate) ?? checkupDate
        
        // 通知をスケジュール
        scheduleEventNotification(
            title: title,
            body: body,
            date: notificationDate,
            identifier: "checkup-\(animalName)-\(checkupDate.timeIntervalSince1970)",
            categoryIdentifier: "CHECKUP",
            userData: ["animalName": animalName, "checkupDate": checkupDate.timeIntervalSince1970]
        )
    }
    
    // ワクチン接種リマインダーの通知をスケジュール
    func scheduleVaccineReminder(animalName: String, vaccineName: String, vaccineDate: Date) {
        let title = "\(animalName)のワクチン接種"
        let body = "明日は\(animalName)の\(vaccineName)ワクチン接種予定日です。"
        
        // 前日に通知
        let notificationDate = Calendar.current.date(byAdding: .day, value: -1, to: vaccineDate) ?? vaccineDate
        
        // 通知をスケジュール
        scheduleEventNotification(
            title: title,
            body: body,
            date: notificationDate,
            identifier: "vaccine-\(animalName)-\(vaccineDate.timeIntervalSince1970)",
            categoryIdentifier: "VACCINE",
            userData: ["animalName": animalName, "vaccineName": vaccineName, "vaccineDate": vaccineDate.timeIntervalSince1970]
        )
    }
}

// UNUserNotificationCenterDelegate プロトコルの実装
extension NotificationManager: UNUserNotificationCenterDelegate {
    // アプリがフォアグラウンドにある状態で通知を受け取った時の処理
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // アプリ起動中でも通知を表示する
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // ユーザーが通知をタップしたときの処理
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let notification = response.notification
        let userInfo = notification.request.content.userInfo
        
        print("通知がタップされました: \(notification.request.identifier)")
        print("通知のカテゴリ: \(notification.request.content.categoryIdentifier)")
        print("通知のユーザーデータ: \(userInfo)")
        
        // カテゴリに基づいて適切な処理を行う
        switch notification.request.content.categoryIdentifier {
        case "PHYSIOLOGICAL":
            // 生理周期関連の通知タップ時の処理
            if let animalName = userInfo["animalName"] as? String {
                print("\(animalName)の生理周期通知がタップされました")
                // 対応する画面に遷移する処理をここに記述
            }
            
        case "CHECKUP":
            // 健康診断関連の通知タップ時の処理
            if let animalName = userInfo["animalName"] as? String,
               let checkupDateTimestamp = userInfo["checkupDate"] as? String,
               let timestamp = Double(checkupDateTimestamp) {
                
                let checkupDate = Date(timeIntervalSince1970: timestamp)
                print("\(animalName)の健康診断通知がタップされました: \(checkupDate)")
                // 対応する画面に遷移する処理をここに記述
            }
            
        case "VACCINE":
            // ワクチン接種関連の通知タップ時の処理
            if let animalName = userInfo["animalName"] as? String,
               let vaccineName = userInfo["vaccineName"] as? String {
                print("\(animalName)の\(vaccineName)ワクチン通知がタップされました")
                // 対応する画面に遷移する処理をここに記述
            }
            
        default:
            // その他の通知タップ時の処理
            print("未分類の通知がタップされました")
        }
        
        // 通知がタップされたので、対応する通知をリストから削除
        removeDeliveredNotification(withIdentifier: notification.request.identifier)
        
        // 完了ハンドラを呼び出す
        completionHandler()
    }
}
