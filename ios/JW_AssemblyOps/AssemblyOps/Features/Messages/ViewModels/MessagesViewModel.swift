//
//  MessagesViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Messages View Model
//
// Manages state and business logic for the messages list.
//
// Published Properties:
//   - messages: Array of Message objects
//   - unreadCount: Count of unread messages
//   - isLoading: Loading state for UI
//   - errorMessage: Error message if fetch fails
//   - hasLoaded: True after first fetch attempt
//   - showUnreadOnly: Filter toggle state
//
// Computed Properties:
//   - filteredMessages: Messages filtered by showUnreadOnly
//   - isEmpty: True if no messages to display
//
// Methods:
//   - fetchMessages(): Fetch messages from API
//   - markAsRead(_:): Mark single message as read
//   - markAllAsRead(): Mark all messages as read
//   - refresh(): Re-fetch messages
//
// Dependencies:
//   - MessagesService: API calls
//
// Used by: MessagesView

import Foundation
import Combine
import SwiftUI
import Apollo

@MainActor
final class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoaded = false
    @Published var showUnreadOnly = false
    @Published var recipients: [RecipientOption] = []

    private var messageSubscription: Apollo.Cancellable?
    private var unreadSubscription: Apollo.Cancellable?
    
    var filteredMessages: [Message] {
        if showUnreadOnly {
            return messages.filter { !$0.isRead }
        }
        return messages
    }
    
    var isEmpty: Bool {
        filteredMessages.isEmpty
    }
    
    /// Fetch messages
    func fetchMessages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let filter = showUnreadOnly 
                ? AssemblyOpsAPI.MessageFilterInput(isRead: .some(false))
                : nil
            messages = try await MessagesService.shared.fetchMessages(filter: filter)
            unreadCount = messages.filter { !$0.isRead }.count
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        hasLoaded = true
    }
    
    /// Fetch just the unread count (for badge)
    func fetchUnreadCount() async {
        do {
            unreadCount = try await MessagesService.shared.fetchUnreadCount()
        } catch {
            print("Failed to fetch unread count: \(error)")
        }
    }
    
    /// Mark a message as read
    func markAsRead(_ message: Message) async {
        guard !message.isRead else { return }
        
        do {
            try await MessagesService.shared.markAsRead(messageId: message.id)
            
            // Update local state
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages[index] = Message(
                    id: message.id,
                    subject: message.subject,
                    body: message.body,
                    recipientType: message.recipientType,
                    senderType: message.senderType,
                    senderName: message.senderName,
                    senderId: message.senderId,
                    conversationId: message.conversationId,
                    isRead: true,
                    readAt: Date(),
                    createdAt: message.createdAt
                )
            }
            unreadCount = max(0, unreadCount - 1)
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }
    
    /// Mark all messages as read
    func markAllAsRead() async {
        do {
            _ = try await MessagesService.shared.markAllAsRead()
            
            // Update local state
            messages = messages.map { message in
                Message(
                    id: message.id,
                    subject: message.subject,
                    body: message.body,
                    recipientType: message.recipientType,
                    senderType: message.senderType,
                    senderName: message.senderName,
                    senderId: message.senderId,
                    conversationId: message.conversationId,
                    isRead: true,
                    readAt: message.readAt ?? Date(),
                    createdAt: message.createdAt
                )
            }
            unreadCount = 0
            
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }
    
    /// Delete a message (soft delete)
    func deleteMessage(_ message: Message) async {
        do {
            _ = try await MessagesService.shared.deleteMessage(messageId: message.id)
            messages.removeAll { $0.id == message.id }
            if !message.isRead {
                unreadCount = max(0, unreadCount - 1)
            }
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    /// Fetch available recipients for compose (excludes current user)
    func fetchRecipients(eventId: String) async {
        do {
            var allRecipients = try await MessagesService.shared.fetchEventParticipants(eventId: eventId)
            // Client-side safety: exclude self by ID
            if let myId = AppState.shared.currentUser?.id {
                allRecipients.removeAll { $0.id == myId }
            }
            recipients = allRecipients
        } catch {
            print("Failed to fetch recipients: \(error)")
        }
    }

    /// Start listening for real-time message updates
    func startListening(eventId: String) {
        stopListening()

        messageSubscription = MessagesService.shared.subscribeToMessages(eventId: eventId) { [weak self] message in
            Task { @MainActor in
                guard let self else { return }
                // Prepend new message if not already present
                if !self.messages.contains(where: { $0.id == message.id }) {
                    self.messages.insert(message, at: 0)
                }
            }
        }

        unreadSubscription = MessagesService.shared.subscribeToUnreadCount { [weak self] count in
            Task { @MainActor in
                self?.unreadCount = count
            }
        }
    }

    /// Stop listening for real-time updates
    func stopListening() {
        messageSubscription?.cancel()
        messageSubscription = nil
        unreadSubscription?.cancel()
        unreadSubscription = nil
    }

    /// Refresh messages
    func refresh() async {
        await fetchMessages()
    }
}
