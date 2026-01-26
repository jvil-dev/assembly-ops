//
//  MessagesService.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Messages Service
//
// Handles all message-related GraphQL API calls.
//
// Methods:
//   - fetchMessages(filter:limit:offset:): Fetch messages for current volunteer
//   - fetchUnreadCount(): Get count of unread messages
//   - markAsRead(messageId:): Mark single message as read
//   - markAllAsRead(): Mark all messages as read, returns count
//
// Dependencies:
//   - NetworkClient: Apollo client for GraphQL
//   - Message: Local message model
//
// Used by: MessagesViewModel, UnreadBadgeManager


import Foundation
import Apollo

/// Service for message operations
final class MessagesService {
    static let shared = MessagesService()
    
    private init() {}
    
    /// Fetch messages for the current volunteer
    func fetchMessages(
        filter: AssemblyOpsAPI.MessageFilterInput? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [Message] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyMessagesQuery(
                    filter: filter.map { .some($0) } ?? .none,
                    limit: .some(limit),
                    offset: .some(offset)
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.myMessages {
                        let messages = data.compactMap { Message(from: $0) }
                        continuation.resume(returning: messages)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: MessagesError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: MessagesError.networkError(error.localizedDescription))
                }
            }
        }
    }
    
    /// Get unread message count
    func fetchUnreadCount() async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.UnreadMessageCountQuery(),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let count = graphQLResult.data?.unreadMessageCount {
                        continuation.resume(returning: count)
                    } else {
                        continuation.resume(returning: 0)
                    }
                case .failure(let error):
                    continuation.resume(throwing: MessagesError.networkError(error.localizedDescription))
                }
            }
        }
    }
    
    /// Mark a message as read
    func markAsRead(messageId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.MarkMessageReadMutation(id: messageId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.errors?.isEmpty ?? true {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: MessagesError.serverError(graphQLResult.errors?.first?.localizedDescription ?? "Unknown error"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: MessagesError.networkError(error.localizedDescription))
                }
            }
        }
    }
    
    /// Mark all messages as read
    func markAllAsRead() async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.MarkAllMessagesReadMutation()
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let message = errors.first?.localizedDescription ?? "Unknown error"
                        continuation.resume(throwing: MessagesError.serverError(message))
                    } else if let count = graphQLResult.data?.markAllMessagesRead.markedCount {
                        continuation.resume(returning: count)
                    } else {
                        continuation.resume(returning: 0)
                    }
                case .failure(let error):
                    continuation.resume(throwing: MessagesError.networkError(error.localizedDescription))
                }
            }
        }
    }
}

/// Messages errors
enum MessagesError: LocalizedError {
    case networkError(String)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message): return "Network error: \(message)"
        case .serverError(let message): return message
        }
    }
}
