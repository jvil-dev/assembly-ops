//
//  SentMessagesViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Sent Messages View Model
//
// Manages state and business logic for viewing sent message history.
// Displays messages sent to volunteers, departments, or entire event.
//
// Published Properties:
//   - messages: List of sent messages
//   - isLoading: Loading state indicator
//   - errorMessage: Error display message
//
// Methods:
//   - loadMessages(eventId:): Fetch sent messages for current event
//   - refresh(eventId:): Pull-to-refresh handler

import Foundation
import Apollo
import Combine

@MainActor
final class SentMessagesViewModel: ObservableObject {
    @Published var messages: [SentMessageItem] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasLoaded = false

    var isEmpty: Bool { messages.isEmpty && hasLoaded }

    func fetchMessages() async {
        isLoading = true
        error = nil
        defer { isLoading = false; hasLoaded = true }
        do {
            messages = try await MessagesService.shared.fetchSentMessages()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func refresh() async {
        await fetchMessages()
    }
}
