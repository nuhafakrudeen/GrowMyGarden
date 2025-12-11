import Photos
import UIKit
import UserNotifications

enum NotificationManager {
    static func currentStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // ✅ FIX: Dispatch back to Main Thread before calling completion
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    static func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }
    static func scheduleRepeating(taskTitle: String,
                                  plantName: String,
                                  identifier: String,
                                  intervalSeconds: TimeInterval) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Time to \(taskTitle.capitalized)"
        content.body  = "Don’t forget to \(taskTitle) your \(plantName) 🌿"
        content.sound = .default

        let seconds = max(60, intervalSeconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: true)

        UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
    static func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
}

enum PhotoPermissionManager {
    static func status() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    static func requestReadWrite(_ completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async { completion(status == .authorized || status == .limited) }
        }
    }
    static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
}
