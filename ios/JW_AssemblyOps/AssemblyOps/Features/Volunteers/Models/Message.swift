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
//  - MessageRecipientType: Enum for message target (volunteer/department/event)
//  - Message: Struct containing message data with formatting helpers
//
// Computed Properties:
//  - displaySubject: Returns subject or "No Subject"
//  - timeAgo: Relative time string (e.g., "2h ago")
//  - formattedDate: Smart date formatting (time if today, date otherwise)
//
// Extensions:
//  - init(from:): Maps GraphQL MyMessagesQuery response to local model
//  - Preview data for SwiftUI previews
//
// Used by: MessagesViewModel, MessageRowView, MessageDetailView

import Foundation

enum MessageRecipientType: String, CaseIterable {
    case volunteer = "VOLUNTEER"
    case department = "DEPARTMENT"
    case event = "EVENT"

    var displayName: String {
        switch self {
        case .volunteer: return "Direct"
        case .department: return "Department"
        case .event: return "Announcement"
        }
    }

    var icon: String {
        switch self {
        case .volunteer: return "person"
        case .department: return "person.2"
        case .event: return "megaphone"
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
        }
    }

    /// Icon for overseer message compose context
    var composeIcon: String {
        switch self {
        case .volunteer: return "person"
        case .department: return "person.3"
        case .event: return "megaphone"
        }
    }
}

/// Local model for message data
struct Message: Identifiable {
    let id: String
    let subject: String?
    let body: String
    let recipientType: MessageRecipientType
    let isRead: Bool
    let readAt: Date?
    let createdAt: Date
    let senderName: String?
    
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

// MARK: - GraphQL Mapping
extension Message {
    init?(from graphQL: AssemblyOpsAPI.MyMessagesQuery.Data.MyMessage) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.body = graphQL.body
        self.recipientType = MessageRecipientType(rawValue: graphQL.recipientType.rawValue) ?? .volunteer
        self.isRead = graphQL.isRead
        
        let isoFormatter = DateUtils.isoFormatter
        
        self.readAt = graphQL.readAt.flatMap { isoFormatter.date(from: $0) }
        
        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt
        
        if let sender = graphQL.sender {
            self.senderName = "\(sender.firstName) \(sender.lastName)"
        } else {
            self.senderName = nil
        }
    }
}

// MARK: - Preview Data
extension Message {
    static var preview: Message {
        Message(id: "1", subject: "Schedule Change", body: "Hello, you've been reassigned to the afternoon shift.", recipientType: .volunteer, isRead: false, readAt: nil, createdAt: Date().addingTimeInterval(-3600), senderName: "Manuel Guzman")
    }
    
    static var previewRead: Message {
        Message(id: "2", subject: "Schedule Change", body: "Hello, you've been reassigned to the afternoon shift.", recipientType: .volunteer, isRead: true, readAt: Date().addingTimeInterval(-3600), createdAt: Date().addingTimeInterval(-7200), senderName: "Manuel Guzman")
    }
    
    static var previewDepartment: Message {
        Message(id: "3", subject: "Schedule Change", body: "Hello, you've been reassigned to the afternoon shift.", recipientType: .department, isRead: false, readAt: nil, createdAt: Date().addingTimeInterval(-3600), senderName: "Department Overseer")
    }
}
