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
//   - fetchMessages(filter:limit:offset:): Fetch inbox messages for current user
//   - fetchUnreadCount(): Get count of unread messages
//   - markAsRead(messageId:): Mark single message as read
//   - markAllAsRead(eventId:): Mark all messages as read, returns count
//   - sendDepartmentMessage(...): Broadcast to department (admin only)
//   - sendBroadcast(...): Broadcast to event (admin only)
//   - fetchConversations(eventId:limit:offset:): Fetch conversation threads
//   - fetchConversationMessages(conversationId:limit:offset:): Fetch thread messages
//   - startConversation(...): Create DM thread + first message
//   - sendConversationMessage(...): Reply in thread
//   - markConversationRead(conversationId:): Mark thread as read
//   - deleteMessage(messageId:): Soft delete a message
//   - deleteConversation(conversationId:): Soft delete a conversation
//   - searchMessages(eventId:query:limit:offset:): Full-text search
//
// Dependencies:
//   - NetworkClient: Apollo client for GraphQL
//   - Message, Conversation: Local models
//
// Used by: MessagesViewModel, ConversationListViewModel, ConversationDetailViewModel, UnreadBadgeManager


import Foundation
import Apollo

/// Service for message operations
final class MessagesService {
    static let shared = MessagesService()

    private init() {}

    // MARK: - Inbox

    /// Fetch inbox messages for the current user (admin or volunteer)
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

    /// Mark all messages as read (optionally scoped to event)
    func markAllAsRead(eventId: String? = nil) async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.MarkAllMessagesReadMutation(
                    eventId: eventId.map { .some($0) } ?? .none
                )
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

    // MARK: - Send Messages

    /// Broadcast to all volunteers in a department — returns conversation ID
    func sendDepartmentMessage(departmentId: String, subject: String?, body: String) async throws -> String {
        let input = AssemblyOpsAPI.SendDepartmentMessageInput(
            departmentId: departmentId,
            subject: subject.map { .some($0) } ?? .none,
            body: body
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.SendDepartmentMessageMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.sendDepartmentMessage {
                        continuation.resume(returning: data.id)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: MessagesError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: MessagesError.serverError("No data returned"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: MessagesError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Broadcast to entire event — returns conversation ID
    func sendBroadcast(eventId: String, subject: String?, body: String) async throws -> String {
        let input = AssemblyOpsAPI.SendBroadcastInput(
            eventId: eventId,
            subject: subject.map { .some($0) } ?? .none,
            body: body
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.SendBroadcastMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.sendBroadcast {
                        continuation.resume(returning: data.id)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: MessagesError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: MessagesError.serverError("No data returned"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: MessagesError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Conversations

    /// Fetch conversation threads for the current user
    func fetchConversations(eventId: String, currentUserId: String?, limit: Int = 50, offset: Int = 0) async throws -> [Conversation] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyConversationsQuery(
                    eventId: eventId,
                    limit: .some(limit),
                    offset: .some(offset)
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.myConversations {
                        let conversations = data.compactMap { Conversation(from: $0, currentUserId: currentUserId) }
                        continuation.resume(returning: conversations)
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

    /// Fetch messages within a conversation thread
    func fetchConversationMessages(conversationId: String, limit: Int = 50, offset: Int = 0) async throws -> [Message] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.ConversationMessagesQuery(
                    conversationId: conversationId,
                    limit: .some(limit),
                    offset: .some(offset)
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.conversationMessages {
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

    /// Start a new conversation thread
    func startConversation(
        eventId: String,
        recipientType: AssemblyOpsAPI.MessageSenderType,
        recipientId: String,
        subject: String?,
        body: String,
        currentUserId: String?
    ) async throws -> Conversation {
        let input = AssemblyOpsAPI.StartConversationInput(
            eventId: eventId,
            recipientType: .case(recipientType),
            recipientId: recipientId,
            subject: subject.map { .some($0) } ?? .none,
            body: body
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.StartConversationMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.startConversation,
                       let conversation = Conversation(from: data, currentUserId: currentUserId) {
                        continuation.resume(returning: conversation)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: MessagesError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: MessagesError.serverError("Failed to start conversation"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: MessagesError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Send a reply in a conversation thread
    func sendConversationMessage(conversationId: String, body: String) async throws -> Message {
        let input = AssemblyOpsAPI.SendConversationMessageInput(
            conversationId: conversationId,
            body: body
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.SendConversationMessageMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.sendConversationMessage,
                       let message = Message(from: data) {
                        continuation.resume(returning: message)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: MessagesError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: MessagesError.serverError("Failed to send message"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: MessagesError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Mark a conversation thread as read
    func markConversationRead(conversationId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.MarkConversationReadMutation(id: conversationId)
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

    // MARK: - Delete

    /// Soft delete a message
    func deleteMessage(messageId: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteMessageMutation(id: messageId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: MessagesError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        let success = graphQLResult.data?.deleteMessage ?? false
                        continuation.resume(returning: success)
                    }
                case .failure(let error):
                    continuation.resume(throwing: MessagesError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Soft delete a conversation
    func deleteConversation(conversationId: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteConversationMutation(id: conversationId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: MessagesError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        let success = graphQLResult.data?.deleteConversation ?? false
                        continuation.resume(returning: success)
                    }
                case .failure(let error):
                    continuation.resume(throwing: MessagesError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Participants

    /// Fetch event participants for the recipient picker (admins + volunteers, excluding self)
    func fetchEventParticipants(eventId: String) async throws -> [RecipientOption] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.EventParticipantsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.eventParticipants {
                        let recipients = data.map { p in
                            RecipientOption(
                                id: p.id,
                                displayName: p.displayName,
                                isAdmin: p.isAdmin
                            )
                        }
                        continuation.resume(returning: recipients)
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

    // MARK: - Search

    /// Full-text search on messages
    func searchMessages(eventId: String, query: String, limit: Int = 50, offset: Int = 0) async throws -> [Message] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.SearchMessagesQuery(
                    eventId: eventId,
                    query: query,
                    limit: .some(limit),
                    offset: .some(offset)
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.searchMessages {
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
    // MARK: - Subscriptions

    /// Subscribe to new messages for an event. Returns a Cancellable to stop listening.
    func subscribeToMessages(eventId: String, handler: @escaping (Message) -> Void) -> Apollo.Cancellable {
        NetworkClient.shared.apollo.subscribe(
            subscription: AssemblyOpsAPI.MessageReceivedSubscription(eventId: eventId)
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let data = graphQLResult.data?.messageReceived,
                   let message = Message(from: data) {
                    handler(message)
                }
            case .failure:
                break
            }
        }
    }

    /// Subscribe to messages in a conversation thread.
    func subscribeToConversation(conversationId: String, handler: @escaping (Message) -> Void) -> Apollo.Cancellable {
        NetworkClient.shared.apollo.subscribe(
            subscription: AssemblyOpsAPI.ConversationMessageReceivedSubscription(conversationId: conversationId)
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let data = graphQLResult.data?.conversationMessageReceived,
                   let message = Message(from: data) {
                    handler(message)
                }
            case .failure:
                break
            }
        }
    }

    /// Subscribe to unread count updates.
    func subscribeToUnreadCount(handler: @escaping (Int) -> Void) -> Apollo.Cancellable {
        NetworkClient.shared.apollo.subscribe(
            subscription: AssemblyOpsAPI.UnreadCountUpdatedSubscription()
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let count = graphQLResult.data?.unreadCountUpdated {
                    #if DEBUG
                    print("[UnreadBadge] Subscription received count: \(count)")
                    #endif
                    handler(count)
                }
            case .failure(let error):
                #if DEBUG
                print("[UnreadBadge] Subscription error: \(error)")
                #endif
                break
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
