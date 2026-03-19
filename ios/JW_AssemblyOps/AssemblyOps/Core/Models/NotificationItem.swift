//
//  NotificationItem.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/7/26.
//

import Foundation

struct NotificationData {
    let conversationId: String?
    let messageId: String?
    let eventId: String?
    let type: String?

    init?(jsonString: String?) {
        guard let jsonString,
              let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        self.conversationId = dict["conversationId"] as? String
        self.messageId = dict["messageId"] as? String
        self.eventId = dict["eventId"] as? String
        self.type = dict["type"] as? String
    }
}

struct NotificationItem: Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String
    let data: String?
    var isRead: Bool
    let createdAt: Date

    lazy var parsedData: NotificationData? = NotificationData(jsonString: data)

    private static let messageTypes: Set<String> = [
        "NEW_MESSAGE", "CONVERSATION_MESSAGE", "DEPARTMENT_MESSAGE", "BROADCAST"
    ]

    var isMessageType: Bool {
        if Self.messageTypes.contains(type) { return true }
        if let parsed = NotificationData(jsonString: data),
           let dataType = parsed.type,
           Self.messageTypes.contains(dataType) {
            return true
        }
        return false
    }

    var icon: String {
        switch type {
        case "ASSIGNMENT_CREATED": return "plus.circle.fill"
        case "ASSIGNMENT_UPDATED": return "pencil.circle.fill"
        case "ASSIGNMENT_CANCELLED": return "xmark.circle.fill"
        case "ASSIGNMENT_FORCE_ASSIGNED": return "bolt.circle.fill"
        case "ASSIGNMENT_ACCEPTED": return "checkmark.circle.fill"
        case "ASSIGNMENT_DECLINED": return "minus.circle.fill"
        case "JOIN_REQUEST_SUBMITTED": return "person.badge.plus"
        case "JOIN_REQUEST_APPROVED": return "person.crop.circle.badge.checkmark"
        case "JOIN_REQUEST_DENIED": return "person.crop.circle.badge.xmark"
        case "ATTENDANCE_COUNT_SUBMITTED": return "number.circle.fill"
        case "NEW_MESSAGE", "CONVERSATION_MESSAGE": return "envelope.fill"
        case "DEPARTMENT_MESSAGE": return "megaphone.fill"
        case "BROADCAST": return "speaker.wave.2.fill"
        default: return "bell.fill"
        }
    }

    var timeAgo: String {
        DateUtils.timeAgo(from: createdAt)
    }
}
