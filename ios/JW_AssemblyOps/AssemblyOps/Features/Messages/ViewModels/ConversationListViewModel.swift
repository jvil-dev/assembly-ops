//
//  ConversationListViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Conversation List View Model
//
// Manages state for the conversation threads list.
//
// Published Properties:
//   - conversations: Array of Conversation threads
//   - isLoading: Loading state
//   - errorMessage: Error display message
//   - hasLoaded: True after first fetch
//
// Methods:
//   - fetchConversations(): Fetch threads from API
//   - deleteConversation(_:): Soft delete a thread
//   - refresh(): Re-fetch conversations
//
// Used by: ConversationListView

import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
final class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoaded = false

    private let eventId: String
    private let currentUserId: String?
    private var messageSubscription: Apollo.Cancellable?

    init(eventId: String, currentUserId: String?) {
        self.eventId = eventId
        self.currentUserId = currentUserId
    }

    var isEmpty: Bool {
        conversations.isEmpty
    }

    var broadcastConversations: [Conversation] {
        conversations.filter { $0.isBroadcast }
    }

    var directConversations: [Conversation] {
        conversations.filter { !$0.isBroadcast }
    }

    func fetchConversations() async {
        isLoading = true
        errorMessage = nil

        do {
            conversations = try await MessagesService.shared.fetchConversations(
                eventId: eventId,
                currentUserId: currentUserId
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        hasLoaded = true
    }

    func deleteConversation(_ conversation: Conversation) async {
        do {
            _ = try await MessagesService.shared.deleteConversation(conversationId: conversation.id)
            conversations.removeAll { $0.id == conversation.id }
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    /// Start listening — re-fetches conversation list when any message arrives
    func startListening() {
        stopListening()
        messageSubscription = MessagesService.shared.subscribeToMessages(eventId: eventId) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchConversations()
            }
        }
    }

    /// Stop listening for real-time updates
    func stopListening() {
        messageSubscription?.cancel()
        messageSubscription = nil
    }

    func refresh() async {
        await fetchConversations()
    }
}
