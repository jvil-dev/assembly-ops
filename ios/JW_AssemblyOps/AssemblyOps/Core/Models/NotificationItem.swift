//
//  NotificationItem.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/7/26.
//

import Foundation

struct NotificationItem: Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String
    let data: String?
    var isRead: Bool
    let createdAt: Date

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
        default: return "bell.fill"
        }
    }

    var timeAgo: String {
        DateUtils.timeAgo(from: createdAt)
    }
}
