//
//  NotificationHistoryService.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/7/26.
//

// MARK: - Notification History Service
//
// GraphQL client for notification history queries and mutations.
// Follows existing service pattern (singleton, NOT @MainActor, withCheckedThrowingContinuation).
//
// Methods:
//   - fetchNotifications(eventId:limit:offset:): Paginated notification history
//   - fetchUnreadCount(eventId:): Count of unread notifications
//   - markRead(notificationId:): Mark single notification as read
//   - markAllRead(eventId:): Mark all notifications for event as read
//
// Used by: NotificationHistoryViewModel

import Foundation
import Apollo

final class NotificationHistoryService {
    static let shared = NotificationHistoryService()
    private init() {}

    func fetchNotifications(eventId: String, limit: Int = 20, offset: Int = 0) async throws -> [NotificationItem] {
        let result: AssemblyOpsAPI.MyNotificationsQuery.Data = try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyNotificationsQuery(
                    eventId: eventId,
                    limit: .some(limit),
                    offset: .some(offset)
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to fetch notifications"))
                        return
                    }
                    guard let data = graphQLResult.data else {
                        continuation.resume(throwing: NetworkError.graphQL("No data returned"))
                        return
                    }
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }

        return result.myNotifications.map { n in
            NotificationItem(
                id: String(n.id),
                type: n.type,
                title: n.title,
                body: n.body,
                data: n.data,
                isRead: n.isRead,
                createdAt: DateUtils.parseISO8601(String(describing: n.createdAt)) ?? Date()
            )
        }
    }

    func fetchUnreadCount(eventId: String) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.UnreadNotificationCountQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to fetch count"))
                        return
                    }
                    continuation.resume(returning: graphQLResult.data?.unreadNotificationCount ?? 0)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func markRead(notificationId: String) async throws {
        let _: Bool = try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.MarkNotificationReadMutation(notificationId: notificationId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to mark read"))
                        return
                    }
                    continuation.resume(returning: graphQLResult.data?.markNotificationRead ?? false)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func markAllRead(eventId: String) async throws {
        let _: Bool = try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.MarkAllNotificationsReadMutation(eventId: eventId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to mark all read"))
                        return
                    }
                    continuation.resume(returning: graphQLResult.data?.markAllNotificationsRead ?? false)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
