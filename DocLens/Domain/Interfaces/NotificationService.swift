import Foundation

/// Service for triggering local push notifications.
protocol NotificationService: Sendable {
    /// Requests authorization for notifications if not already granted.
    func requestAuthorization() async throws -> Bool
    
    /// Triggers a local notification immediately.
    func scheduleLocalNotification(title: String, body: String) async throws
}
