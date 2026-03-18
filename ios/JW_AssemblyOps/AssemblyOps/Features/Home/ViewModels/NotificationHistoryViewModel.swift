//
//  NotificationHistoryViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/7/26.
//

// MARK: - Notification History View Model
//
// Fetches and manages notification history for an event.
//
// Published Properties:
//   - notifications: Array of NotificationItem objects
//   - unreadCount: Count of unread notifications
//   - isLoading: True while fetching
//   - errorMessage: Error text (nil on success)
//
// Methods:
//   - loadNotifications(eventId:): Fetch from API
//   - loadUnreadCount(eventId:): Fetch unread count
//   - markRead(notification:): Mark single as read
//   - markAllRead(eventId:): Mark all as read
//   - loadMore(eventId:): Load next page
//
// Used by: NotificationHistoryView, EventHomeView (unread count)

import Foundation
import Combine

@MainActor
final class NotificationHistoryViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMorePages = true

    private let pageSize = 20
    private let service = NotificationHistoryService.shared

    func loadNotifications(eventId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let items = try await service.fetchNotifications(eventId: eventId, limit: pageSize, offset: 0)
            notifications = items
            hasMorePages = items.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadUnreadCount(eventId: String) async {
        do {
            unreadCount = try await service.fetchUnreadCount(eventId: eventId)
        } catch {
            // Silently fail for badge count
        }
    }

    func loadMore(eventId: String) async {
        guard hasMorePages, !isLoading else { return }
        isLoading = true
        do {
            let items = try await service.fetchNotifications(eventId: eventId, limit: pageSize, offset: notifications.count)
            notifications.append(contentsOf: items)
            hasMorePages = items.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func markRead(_ notification: NotificationItem) async {
        guard !notification.isRead else { return }
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            unreadCount = max(0, unreadCount - 1)
        }
        do {
            try await service.markRead(notificationId: notification.id)
        } catch {
            // Revert on failure
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = false
                unreadCount += 1
            }
        }
    }

    func deleteNotification(_ notification: NotificationItem) async {
        let previousNotifications = notifications
        let previousCount = unreadCount
        notifications.removeAll { $0.id == notification.id }
        if !notification.isRead {
            unreadCount = max(0, unreadCount - 1)
        }
        do {
            try await service.deleteNotification(notificationId: notification.id)
        } catch {
            notifications = previousNotifications
            unreadCount = previousCount
        }
    }

    func markAllRead(eventId: String) async {
        let previousNotifications = notifications
        let previousCount = unreadCount
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        unreadCount = 0
        do {
            try await service.markAllRead(eventId: eventId)
        } catch {
            notifications = previousNotifications
            unreadCount = previousCount
        }
    }
}
