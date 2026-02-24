//
//  SentMessage.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Sent Message Model
//
// Local model for sent message data from GraphQL API.
//
// Properties:
//   - id: Unique message identifier
//   - subject: Optional message subject
//   - body: Message content
//   - recipientType: Message target (VOLUNTEER, DEPARTMENT, EVENT)
//   - recipientName: Display name for recipient (volunteer name or department/event name)
//   - createdAt: Timestamp when message was sent
//
// Computed Properties:
//   - recipientTypeDisplayName: User-friendly label for recipient type

import Foundation

struct SentMessageItem: Identifiable {
    let id: String
    let subject: String?
    let body: String
    let recipientType: String
    let recipientName: String?
    let isRead: Bool
    let readAt: Date?
    let createdAt: Date

    var recipientTypeDisplayName: String {
        switch recipientType {
        case "VOLUNTEER": return "Individual"
        case "DEPARTMENT": return "Department"
        case "EVENT": return "Event Broadcast"
        default: return recipientType
        }
    }
}

// MARK: - GraphQL Mapping
extension SentMessageItem {
    init?(from graphQL: AssemblyOpsAPI.SentMessagesQuery.Data.SentMessage) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.body = graphQL.body
        self.recipientType = graphQL.recipientType.rawValue
        self.isRead = graphQL.isRead

        let isoFormatter = DateUtils.isoFormatter

        self.readAt = graphQL.readAt.flatMap { isoFormatter.date(from: $0) }

        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt

        // Extract recipient name from volunteer field if present
        if let volunteer = graphQL.volunteer {
            self.recipientName = "\(volunteer.firstName) \(volunteer.lastName)"
        } else {
            self.recipientName = nil
        }
    }

    // Overload for SendMessage mutation response
    init?(from graphQL: AssemblyOpsAPI.SendMessageMutation.Data.SendMessage) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.body = graphQL.body
        self.recipientType = graphQL.recipientType.rawValue
        self.isRead = false
        self.readAt = nil

        let isoFormatter = DateUtils.isoFormatter
        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt

        if let volunteer = graphQL.volunteer {
            self.recipientName = "\(volunteer.firstName) \(volunteer.lastName)"
        } else {
            self.recipientName = nil
        }
    }

    // Overload for SendDepartmentMessage mutation response
    init?(from graphQL: AssemblyOpsAPI.SendDepartmentMessageMutation.Data.SendDepartmentMessage) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.body = graphQL.body
        self.recipientType = graphQL.recipientType.rawValue
        self.isRead = false
        self.readAt = nil

        let isoFormatter = DateUtils.isoFormatter
        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt
        self.recipientName = nil
    }

    // Overload for SendBroadcast mutation response
    init?(from graphQL: AssemblyOpsAPI.SendBroadcastMutation.Data.SendBroadcast) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.body = graphQL.body
        self.recipientType = graphQL.recipientType.rawValue
        self.isRead = false
        self.readAt = nil

        let isoFormatter = DateUtils.isoFormatter
        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt
        self.recipientName = nil
    }

    // Overload for SendMultiMessage mutation response
    init?(from graphQL: AssemblyOpsAPI.SendMultiMessageMutation.Data.SendMultiMessage) {
        self.id = graphQL.id
        self.subject = graphQL.subject
        self.body = graphQL.body
        self.recipientType = graphQL.recipientType.rawValue
        self.isRead = false
        self.readAt = nil

        let isoFormatter = DateUtils.isoFormatter
        guard let createdAt = isoFormatter.date(from: graphQL.createdAt) else {
            return nil
        }
        self.createdAt = createdAt

        if let volunteer = graphQL.volunteer {
            self.recipientName = "\(volunteer.firstName) \(volunteer.lastName)"
        } else {
            self.recipientName = nil
        }
    }
}
