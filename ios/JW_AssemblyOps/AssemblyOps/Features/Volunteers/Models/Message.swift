//
//  Message.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Message Model
//
// Local model for message data from GraphQL API
//
// Types:
//  - MessageSenderType: Enum for sender identity (admin/volunteer)
//  - MessageRecipientType: Enum for message target (volunteer/department/event/admin)
//  - Message: Struct containing message data with formatting helpers
//
// Computed Properties:
//  - displaySubject: Returns subject or "No Subject"
//  - timeAgo: Relative time string (e.g., "2h ago")
//  - formattedDate: Smart date formatting (time if today, date otherwise)
//
// Extensions:
//  - init(from:): Maps GraphQL responses to local model
//  - Preview data for SwiftUI previews
//
// Used by: MessagesViewModel, MessageRowView, MessageDetailView, ConversationDetailViewModel

import Foundation

enum MessageSenderType: String, CaseIterable {
    case admin = "ADMIN"
    case volunteer = "VOLUNTEER"

    var displayName: String {
        switch self {
        case .admin: return "Overseer"
        case .volunteer: return "Volunteer"
        }
    }
}

enum MessageRecipientType: String, CaseIterable {
    case volunteer = "VOLUNTEER"
    case department = "DEPARTMENT"
    case event = "EVENT"
    case admin = "ADMIN"

    var displayName: String {
        switch self {
        case .volunteer: return "Direct"
        case .department: return "Department"
        case .event: return "Announcement"
        case .admin: return "Overseer"
        }
    }

    var icon: String {
        switch self {
        case .volunteer: return "person"
        case .department: return "person.2"
        case .event: return "megaphone"
        case .admin: return "person.badge.shield.checkmark"
        }
    }
}

// MARK: - Overseer Compose Extension
extension MessageRecipientType {
    /// Display name for overseer message compose context
    var composeDisplayName: String {
        switch self {
        case .volunteer: return "Individual Volunteer"
        case .department: return "Department"
        case .event: return "Event Broadcast"
        case .admin: return "Overseer"
        }
    }

    /// Icon for overseer message compose context
    var composeIcon: String {
        switch self {
        case .volunteer: return "person"
        case .department: return "person.3"
        case .event: return "megaphone"
        case .admin: return "person.badge.shield.checkmark"
        }
    }
}

/// Local model for message data
struct Message: Identifiable {
    let id: String
    let subject: String?
    let body: String
    let recipientType: MessageRecipientType
    let senderType: MessageSenderType?
    let senderName: String?
    let senderId: String?
    let conversationId: String?
    let isRead: Bool
    let readAt: Date?
    let createdAt: Date

    var displaySubject: String {
        subject ?? "No Subject"
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(createdAt) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
        } else if Calendar.current.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        }
        return formatter.string(from: createdAt)
    }
}

// MARK: - GraphQL Mapping (MyMessages)
extension Message {
    init?(from graphQL: AssemblyOpsAPI.MyMessagesQuery.Data.MyMessage) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.body = graphQL.body
        self.recipientType = MessageRecipientType(rawValue: graphQL.recipientType.rawValue) ?? .volunteer
        self.senderType = graphQL.senderType.flatMap { MessageSenderType(rawValue: $0.rawValue) }
        self.senderId = graphQL.senderId
        self.conversationId = graphQL.conversation?.id
        self.isRead = graphQL.isRead

        let isoFormatter = DateUtils.isoFormatter

        self.readAt = graphQL.readAt.flatMap { isoFormatter.date(from: $0) }

        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt

        // Prefer computed senderName from resolver, fallback to sender relation
        if let name = graphQL.senderName {
            self.senderName = name
        } else if let sender = graphQL.sender {
            self.senderName = "\(sender.firstName) \(sender.lastName)"
        } else {
            self.senderName = nil
        }
    }
}

// MARK: - GraphQL Mapping (ConversationMessages)
extension Message {
    init?(from graphQL: AssemblyOpsAPI.ConversationMessagesQuery.Data.ConversationMessage) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.body = graphQL.body
        self.recipientType = MessageRecipientType(rawValue: graphQL.recipientType.rawValue) ?? .volunteer
        self.senderType = graphQL.senderType.flatMap { MessageSenderType(rawValue: $0.rawValue) }
        self.senderName = graphQL.senderName
        self.senderId = graphQL.senderId
        self.conversationId = nil
        self.isRead = graphQL.isRead

        let isoFormatter = DateUtils.isoFormatter
        self.readAt = graphQL.readAt.flatMap { isoFormatter.date(from: $0) }

        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt
    }
}

// MARK: - GraphQL Mapping (SearchMessages)
extension Message {
    init?(from graphQL: AssemblyOpsAPI.SearchMessagesQuery.Data.SearchMessage) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.body = graphQL.body
        self.recipientType = MessageRecipientType(rawValue: graphQL.recipientType.rawValue) ?? .volunteer
        self.senderType = graphQL.senderType.flatMap { MessageSenderType(rawValue: $0.rawValue) }
        self.senderName = graphQL.senderName
        self.senderId = graphQL.senderId
        self.conversationId = nil
        self.isRead = graphQL.isRead

        let isoFormatter = DateUtils.isoFormatter
        self.readAt = graphQL.readAt.flatMap { isoFormatter.date(from: $0) }

        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt
    }
}

// MARK: - GraphQL Mapping (SendConversationMessage)
extension Message {
    init?(from graphQL: AssemblyOpsAPI.SendConversationMessageMutation.Data.SendConversationMessage) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.body = graphQL.body
        self.recipientType = MessageRecipientType(rawValue: graphQL.recipientType.rawValue) ?? .volunteer
        self.senderType = graphQL.senderType.flatMap { MessageSenderType(rawValue: $0.rawValue) }
        self.senderName = graphQL.senderName
        self.senderId = graphQL.senderId
        self.conversationId = nil
        self.isRead = graphQL.isRead

        let isoFormatter = DateUtils.isoFormatter

        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt
        self.readAt = nil
    }
}

// MARK: - Preview Data
extension Message {
    static var preview: Message {
        Message(id: "1", subject: "Schedule Change", body: "Hello, you've been reassigned to the afternoon shift.", recipientType: .volunteer, senderType: .admin, senderName: "Manuel Guzman", senderId: "admin-1", conversationId: nil, isRead: false, readAt: nil, createdAt: Date().addingTimeInterval(-3600))
    }

    static var previewRead: Message {
        Message(id: "2", subject: "Schedule Change", body: "Hello, you've been reassigned to the afternoon shift.", recipientType: .volunteer, senderType: .admin, senderName: "Manuel Guzman", senderId: "admin-1", conversationId: nil, isRead: true, readAt: Date().addingTimeInterval(-3600), createdAt: Date().addingTimeInterval(-7200))
    }

    static var previewDepartment: Message {
        Message(id: "3", subject: "Schedule Change", body: "Hello, you've been reassigned to the afternoon shift.", recipientType: .department, senderType: .admin, senderName: "Department Overseer", senderId: "admin-2", conversationId: nil, isRead: false, readAt: nil, createdAt: Date().addingTimeInterval(-3600))
    }

    static var previewVolunteerSent: Message {
        Message(id: "4", subject: "Question", body: "I have a question about my post assignment for tomorrow.", recipientType: .admin, senderType: .volunteer, senderName: "Carlos Martinez", senderId: "vol-1", conversationId: "conv-1", isRead: false, readAt: nil, createdAt: Date().addingTimeInterval(-1800))
    }
}
