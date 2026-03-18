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
//   - type: DIRECT, DEPARTMENT_BROADCAST, or EVENT_BROADCAST
//   - departmentName: Name of department (for department broadcasts)
//   - lastMessageBody: Preview text from most recent message
//   - lastMessageSenderName: Sender of most recent message
//   - lastMessageDate: Timestamp of most recent message
//   - otherParticipantName: Display name of the other participant (or broadcast name)
//   - unreadCount: Number of unread messages in thread
//   - updatedAt: Last activity timestamp
//
// Used by: ConversationListViewModel, ConversationDetailViewModel

import Foundation

enum ConversationType: String {
    case direct = "DIRECT"
    case departmentBroadcast = "DEPARTMENT_BROADCAST"
    case eventBroadcast = "EVENT_BROADCAST"
}

struct Conversation: Identifiable, Hashable {
    let id: String
    let subject: String?
    let type: ConversationType
    let departmentName: String?
    let lastMessageBody: String?
    let lastMessageSenderName: String?
    let lastMessageDate: Date?
    let otherParticipantName: String
    let otherParticipantId: String
    let otherParticipantPhone: String?
    let otherParticipantCongregation: String?
    let unreadCount: Int
    let updatedAt: Date

    var isBroadcast: Bool { type != .direct }

    var displayName: String {
        switch type {
        case .direct:
            return otherParticipantName
        case .departmentBroadcast:
            return departmentName ?? NSLocalizedString("messages.broadcast.department", comment: "")
        case .eventBroadcast:
            return subject ?? NSLocalizedString("messages.broadcast.event", comment: "")
        }
    }
}

// MARK: - GraphQL Mapping
extension Conversation {
    init?(from graphQL: AssemblyOpsAPI.MyConversationsQuery.Data.MyConversation, currentUserId: String?) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.departmentName = graphQL.departmentName
        self.unreadCount = graphQL.unreadCount

        // Map conversation type
        switch graphQL.type.rawValue {
        case "DEPARTMENT_BROADCAST":
            self.type = .departmentBroadcast
        case "EVENT_BROADCAST":
            self.type = .eventBroadcast
        default:
            self.type = .direct
        }

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

        // For broadcast types, use display name logic instead of "find other participant"
        if self.type != .direct {
            let name: String
            switch self.type {
            case .departmentBroadcast:
                name = graphQL.departmentName ?? NSLocalizedString("messages.broadcast.department", comment: "")
            case .eventBroadcast:
                name = graphQL.subject ?? NSLocalizedString("messages.broadcast.event", comment: "")
            case .direct:
                name = "Unknown"
            }
            self.otherParticipantName = name
            self.otherParticipantId = ""
            self.otherParticipantPhone = nil
            self.otherParticipantCongregation = nil
        } else {
            let otherParticipant = graphQL.participants.first { $0.participantId != currentUserId }
            self.otherParticipantName = otherParticipant?.displayName ?? graphQL.participants.first?.displayName ?? "Unknown"
            self.otherParticipantId = otherParticipant?.participantId ?? graphQL.participants.first?.participantId ?? ""
            self.otherParticipantPhone = otherParticipant?.phone
            self.otherParticipantCongregation = otherParticipant?.congregation
        }
    }

    init?(from graphQL: AssemblyOpsAPI.StartConversationMutation.Data.StartConversation, currentUserId: String?) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.type = .direct
        self.departmentName = nil
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
        self.otherParticipantId = otherParticipant?.participantId ?? graphQL.participants.first?.participantId ?? ""
        self.otherParticipantPhone = otherParticipant?.phone
        self.otherParticipantCongregation = otherParticipant?.congregation
    }
}

// MARK: - Preview Data
extension Conversation {
    static var preview: Conversation {
        Conversation(
            id: "conv-1",
            subject: "Schedule Question",
            type: .direct,
            departmentName: nil,
            lastMessageBody: "Can I switch to the afternoon shift tomorrow?",
            lastMessageSenderName: "Carlos Martinez",
            lastMessageDate: Date().addingTimeInterval(-1800),
            otherParticipantName: "Carlos Martinez",
            otherParticipantId: "user-2",
            otherParticipantPhone: "555-0123",
            otherParticipantCongregation: "North Valley",
            unreadCount: 2,
            updatedAt: Date().addingTimeInterval(-1800)
        )
    }

    static var previewRead: Conversation {
        Conversation(
            id: "conv-2",
            subject: "Meeting Reminder",
            type: .direct,
            departmentName: nil,
            lastMessageBody: "Don't forget the pre-event briefing at 7am.",
            lastMessageSenderName: "Manuel Guzman",
            lastMessageDate: Date().addingTimeInterval(-7200),
            otherParticipantName: "Manuel Guzman",
            otherParticipantId: "user-3",
            otherParticipantPhone: nil,
            otherParticipantCongregation: "East Side",
            unreadCount: 0,
            updatedAt: Date().addingTimeInterval(-7200)
        )
    }

    static var previewBroadcast: Conversation {
        Conversation(
            id: "conv-3",
            subject: "Event Announcements",
            type: .eventBroadcast,
            departmentName: nil,
            lastMessageBody: "Please arrive 30 minutes early tomorrow.",
            lastMessageSenderName: "Jorge Villeda",
            lastMessageDate: Date().addingTimeInterval(-3600),
            otherParticipantName: "Event Announcement",
            otherParticipantId: "",
            otherParticipantPhone: nil,
            otherParticipantCongregation: nil,
            unreadCount: 1,
            updatedAt: Date().addingTimeInterval(-3600)
        )
    }

    static var previewDeptBroadcast: Conversation {
        Conversation(
            id: "conv-4",
            subject: nil,
            type: .departmentBroadcast,
            departmentName: "Attendant",
            lastMessageBody: "New post assignments have been updated.",
            lastMessageSenderName: "Jorge Villeda",
            lastMessageDate: Date().addingTimeInterval(-5400),
            otherParticipantName: "Attendant",
            otherParticipantId: "",
            otherParticipantPhone: nil,
            otherParticipantCongregation: nil,
            unreadCount: 0,
            updatedAt: Date().addingTimeInterval(-5400)
        )
    }
}
