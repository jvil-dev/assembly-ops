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

@MainActor
final class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoaded = false

    private let eventId: String
    private let currentUserId: String?

    init(eventId: String, currentUserId: String?) {
        self.eventId = eventId
        self.currentUserId = currentUserId
    }

    var isEmpty: Bool {
        conversations.isEmpty
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

    func refresh() async {
        await fetchConversations()
    }
}
