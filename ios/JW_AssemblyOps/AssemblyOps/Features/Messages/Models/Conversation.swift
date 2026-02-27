//
//  Conversation.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Conversation Model
//
// Local model for conversation thread data from GraphQL API.
//
// Properties:
//   - id: Unique conversation identifier
//   - subject: Optional conversation subject
//   - lastMessageBody: Preview text from most recent message
//   - lastMessageSenderName: Sender of most recent message
//   - lastMessageDate: Timestamp of most recent message
//   - otherParticipantName: Display name of the other participant
//   - unreadCount: Number of unread messages in thread
//   - updatedAt: Last activity timestamp
//
// Used by: ConversationListViewModel, ConversationDetailViewModel

import Foundation

struct Conversation: Identifiable, Hashable {
    let id: String
    let subject: String?
    let lastMessageBody: String?
    let lastMessageSenderName: String?
    let lastMessageDate: Date?
    let otherParticipantName: String
    let unreadCount: Int
    let updatedAt: Date
}

// MARK: - GraphQL Mapping
extension Conversation {
    init?(from graphQL: AssemblyOpsAPI.MyConversationsQuery.Data.MyConversation, currentUserId: String?) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.unreadCount = graphQL.unreadCount

        let isoFormatter = DateUtils.isoFormatter

        guard let updatedAt = isoFormatter.date(from: graphQL.updatedAt) else {
            return nil
        }
        self.updatedAt = updatedAt

        // Extract last message preview
        if let lastMsg = graphQL.lastMessage {
            self.lastMessageBody = lastMsg.body
            self.lastMessageSenderName = lastMsg.senderName
            self.lastMessageDate = isoFormatter.date(from: lastMsg.createdAt)
        } else {
            self.lastMessageBody = nil
            self.lastMessageSenderName = nil
            self.lastMessageDate = nil
        }

        // Find the other participant's name
        let otherParticipant = graphQL.participants.first { $0.participantId != currentUserId }
        self.otherParticipantName = otherParticipant?.displayName ?? graphQL.participants.first?.displayName ?? "Unknown"
    }

    init?(from graphQL: AssemblyOpsAPI.StartConversationMutation.Data.StartConversation, currentUserId: String?) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.unreadCount = graphQL.unreadCount

        let isoFormatter = DateUtils.isoFormatter

        guard let updatedAt = isoFormatter.date(from: graphQL.updatedAt) else {
            return nil
        }
        self.updatedAt = updatedAt

        if let lastMsg = graphQL.lastMessage {
            self.lastMessageBody = lastMsg.body
            self.lastMessageSenderName = lastMsg.senderName
            self.lastMessageDate = isoFormatter.date(from: lastMsg.createdAt)
        } else {
            self.lastMessageBody = nil
            self.lastMessageSenderName = nil
            self.lastMessageDate = nil
        }

        let otherParticipant = graphQL.participants.first { $0.participantId != currentUserId }
        self.otherParticipantName = otherParticipant?.displayName ?? graphQL.participants.first?.displayName ?? "Unknown"
    }
}

// MARK: - Preview Data
extension Conversation {
    static var preview: Conversation {
        Conversation(
            id: "conv-1",
            subject: "Schedule Question",
            lastMessageBody: "Can I switch to the afternoon shift tomorrow?",
            lastMessageSenderName: "Carlos Martinez",
            lastMessageDate: Date().addingTimeInterval(-1800),
            otherParticipantName: "Carlos Martinez",
            unreadCount: 2,
            updatedAt: Date().addingTimeInterval(-1800)
        )
    }

    static var previewRead: Conversation {
        Conversation(
            id: "conv-2",
            subject: "Meeting Reminder",
            lastMessageBody: "Don't forget the pre-event briefing at 7am.",
            lastMessageSenderName: "Manuel Guzman",
            lastMessageDate: Date().addingTimeInterval(-7200),
            otherParticipantName: "Manuel Guzman",
            unreadCount: 0,
            updatedAt: Date().addingTimeInterval(-7200)
        )
    }
}
