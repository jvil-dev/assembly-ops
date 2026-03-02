//
//  MessageTemplate.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/23/26.
//

// MARK: - Message Template Model
//
// System-defined message templates for quick compose.
// Templates are hard-coded (no backend storage).
//
// Used by: MessageTemplateSheet, MessageComposeView

import Foundation

struct MessageTemplate: Identifiable {
    let id: UUID
    let category: TemplateCategory
    let title: String
    let subject: String
    let body: String

    enum TemplateCategory: String, CaseIterable {
        case scheduling = "Scheduling"
        case reminder = "Reminders"
        case general = "General"

        var icon: String {
            switch self {
            case .scheduling: return "calendar"
            case .reminder: return "bell"
            case .general: return "text.bubble"
            }
        }
    }

    static let templates: [MessageTemplate] = [
        // Scheduling
        MessageTemplate(
            id: UUID(),
            category: .scheduling,
            title: NSLocalizedString("messages.template.scheduleChange", comment: ""),
            subject: NSLocalizedString("messages.template.scheduleChange.subject", comment: ""),
            body: NSLocalizedString("messages.template.scheduleChange.body", comment: "")
        ),
        MessageTemplate(
            id: UUID(),
            category: .scheduling,
            title: NSLocalizedString("messages.template.newAssignment", comment: ""),
            subject: NSLocalizedString("messages.template.newAssignment.subject", comment: ""),
            body: NSLocalizedString("messages.template.newAssignment.body", comment: "")
        ),
        MessageTemplate(
            id: UUID(),
            category: .scheduling,
            title: NSLocalizedString("messages.template.shiftReminder", comment: ""),
            subject: NSLocalizedString("messages.template.shiftReminder.subject", comment: ""),
            body: NSLocalizedString("messages.template.shiftReminder.body", comment: "")
        ),

        // Reminders
        MessageTemplate(
            id: UUID(),
            category: .reminder,
            title: NSLocalizedString("messages.template.checkInReminder", comment: ""),
            subject: NSLocalizedString("messages.template.checkInReminder.subject", comment: ""),
            body: NSLocalizedString("messages.template.checkInReminder.body", comment: "")
        ),
        MessageTemplate(
            id: UUID(),
            category: .reminder,
            title: NSLocalizedString("messages.template.meetingNotice", comment: ""),
            subject: NSLocalizedString("messages.template.meetingNotice.subject", comment: ""),
            body: NSLocalizedString("messages.template.meetingNotice.body", comment: "")
        ),

        // General
        MessageTemplate(
            id: UUID(),
            category: .general,
            title: NSLocalizedString("messages.template.thankYou", comment: ""),
            subject: NSLocalizedString("messages.template.thankYou.subject", comment: ""),
            body: NSLocalizedString("messages.template.thankYou.body", comment: "")
        ),
        MessageTemplate(
            id: UUID(),
            category: .general,
            title: NSLocalizedString("messages.template.importantNotice", comment: ""),
            subject: NSLocalizedString("messages.template.importantNotice.subject", comment: ""),
            body: NSLocalizedString("messages.template.importantNotice.body", comment: "")
        ),
    ]

    static func templates(for category: TemplateCategory) -> [MessageTemplate] {
        templates.filter { $0.category == category }
    }
}
