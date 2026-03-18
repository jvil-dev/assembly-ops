//
//  ConversationDetailViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Conversation Detail View Model
//
// Manages state for a single conversation thread.
//
// Published Properties:
//   - messages: Array of messages in the thread
//   - isLoading: Loading state
//   - isSending: Sending state
//   - errorMessage: Error display message
//   - hasLoaded: True after first fetch
//
// Methods:
//   - fetchMessages(): Fetch thread messages
//   - sendReply(body:): Send a reply in the thread
//   - markAsRead(): Mark the conversation as read
//
// Used by: ConversationDetailView

import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
final class ConversationDetailViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var hasLoaded = false

    let conversationId: String
    let currentUserId: String?
    private var subscription: Apollo.Cancellable?

    init(conversationId: String, currentUserId: String?) {
        self.conversationId = conversationId
        self.currentUserId = currentUserId
    }

    func fetchMessages() async {
        isLoading = true
        errorMessage = nil

        do {
            messages = try await MessagesService.shared.fetchConversationMessages(
                conversationId: conversationId
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        hasLoaded = true
    }

    func sendReply(body: String) async {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            let newMessage = try await MessagesService.shared.sendConversationMessage(
                conversationId: conversationId,
                body: trimmed
            )
            messages.append(newMessage)
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    func markAsRead() async {
        do {
            try await MessagesService.shared.markConversationRead(conversationId: conversationId)
            // Immediately refresh badge (subscription also pushes update as backup)
            await UnreadBadgeManager.shared.fetchUnreadCount()
        } catch {
            print("Failed to mark conversation read: \(error)")
        }
    }

    /// Start listening for real-time conversation messages
    func startListening() {
        stopListening()
        subscription = MessagesService.shared.subscribeToConversation(conversationId: conversationId) { [weak self] message in
            Task { @MainActor in
                guard let self else { return }
                if !self.messages.contains(where: { $0.id == message.id }) {
                    self.messages.append(message)
                }
            }
        }
    }

    /// Stop listening for real-time updates
    func stopListening() {
        subscription?.cancel()
        subscription = nil
    }

    /// Check if a message was sent by the current user
    func isFromCurrentUser(_ message: Message) -> Bool {
        guard let currentUserId else { return false }
        return message.senderId == currentUserId
    }
}
