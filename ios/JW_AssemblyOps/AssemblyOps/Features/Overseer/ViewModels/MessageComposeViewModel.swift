//
//  MessageComposeViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Message Compose View Model
//
// Manages state and business logic for composing and sending messages.
// Supports individual, department, event, and multi-recipient sends.
//
// Used by: MessageComposeView

import Foundation
import Apollo
import Combine

@MainActor
final class MessageComposeViewModel: ObservableObject {
    @Published var recipientType: MessageRecipientType = .volunteer
    @Published var selectedVolunteerId: String?
    @Published var selectedVolunteerName: String?
    @Published var subject: String = ""
    @Published var body: String = ""
    @Published var isSending = false
    @Published var error: String?
    @Published var didSend = false
    @Published var sentCount: Int = 0

    // Multi-select support
    @Published var isMultiSelect = false
    @Published var selectedVolunteerIds: Set<String> = []

    var isValid: Bool {
        let hasBody = !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch recipientType {
        case .volunteer:
            if isMultiSelect {
                return hasBody && !selectedVolunteerIds.isEmpty
            }
            return hasBody && selectedVolunteerId != nil
        case .admin:
            return hasBody && selectedVolunteerId != nil
        case .department, .event:
            return hasBody
        }
    }

    func applyTemplate(_ template: MessageTemplate) {
        subject = template.subject
        body = template.body
    }

    func send(eventId: String, departmentId: String?) async {
        guard isValid else { return }
        isSending = true
        error = nil
        defer { isSending = false }

        let subjectText = subject.isEmpty ? nil : subject

        do {
            switch recipientType {
            case .volunteer:
                if isMultiSelect {
                    let ids = Array(selectedVolunteerIds)
                    let messages = try await MessagesService.shared.sendMultiMessage(
                        volunteerIds: ids, subject: subjectText, body: body, eventId: eventId
                    )
                    sentCount = messages.count
                } else {
                    guard let volunteerId = selectedVolunteerId else { return }
                    _ = try await MessagesService.shared.sendMessage(
                        volunteerId: volunteerId, subject: subjectText, body: body
                    )
                    sentCount = 1
                }
            case .admin:
                guard let adminId = selectedVolunteerId else { return }
                _ = try await MessagesService.shared.sendMessage(
                    recipientType: .admin, recipientId: adminId, eventId: eventId,
                    subject: subjectText, body: body
                )
                sentCount = 1
            case .department:
                guard let deptId = departmentId else { return }
                let messages = try await MessagesService.shared.sendDepartmentMessage(
                    departmentId: deptId, subject: subjectText, body: body
                )
                sentCount = messages.count
            case .event:
                let messages = try await MessagesService.shared.sendBroadcast(
                    eventId: eventId, subject: subjectText, body: body
                )
                sentCount = messages.count
            }
            HapticManager.shared.success()
            didSend = true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}
