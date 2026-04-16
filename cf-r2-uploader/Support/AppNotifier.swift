import Foundation
import UserNotifications

@MainActor
final class AppNotifier {
    private let center = UNUserNotificationCenter.current()

    init() {
        requestAuthorizationIfNeeded()
    }

    func notifyUploadSucceeded(fileName: String, url: URL) {
        send(
            title: "上传成功",
            body: "\(fileName)\n\(url.absoluteString)"
        )
    }

    func notifyUploadFailed(message: String) {
        send(
            title: "上传失败",
            body: message
        )
    }

    private func requestAuthorizationIfNeeded() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request)
    }
}
