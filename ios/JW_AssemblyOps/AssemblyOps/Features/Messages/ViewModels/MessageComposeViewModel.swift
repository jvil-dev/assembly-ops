//
//  MessageComposeViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Message Compose View Model (Announcement)
//
// Manages state and business logic for composing announcements.
// Supports department and event-wide (broadcast) sends only.
// Individual messaging uses the conversation flow (ComposeMessageView).
//
// Used by: MessageComposeView

import Foundation
import Apollo
import Combine

@MainActor
final class MessageComposeViewModel: ObservableObject {
    @Published var recipientType: MessageRecipientType = .department
    @Published var subject: String = ""
    @Published var body: String = ""
    @Published var isSending = false
    @Published var error: String?
    @Published var didSend = false
    @Published var sentCount: Int = 0

    var isValid: Bool {
        let hasBody = !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch recipientType {
        case .department, .event:
            return hasBody
        case .volunteer, .user:
            return false
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
            case .volunteer, .user:
                return
            case .department:
                guard let deptId = departmentId else { return }
                _ = try await MessagesService.shared.sendDepartmentMessage(
                    departmentId: deptId, subject: subjectText, body: body
                )
                sentCount = 1
            case .event:
                _ = try await MessagesService.shared.sendBroadcast(
                    eventId: eventId, subject: subjectText, body: body
                )
                sentCount = 1
            }
            HapticManager.shared.success()
            didSend = true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}
