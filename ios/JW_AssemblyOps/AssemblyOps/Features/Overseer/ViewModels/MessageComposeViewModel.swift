//
//  MessageComposeViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Message Compose View Model
//
// Manages state and business logic for composing and sending messages.
// Supports three recipient types: individual volunteer, department, event broadcast.
//
// Published Properties:
//   - recipientType: Selected message target (volunteer/department/event)
//   - selectedVolunteerId: ID of selected volunteer (for individual messages)
//   - selectedVolunteerName: Display name of selected volunteer
//   - subject: Optional message subject (shown for individual messages)
//   - body: Message content
//   - isSending: Sending state indicator
//   - errorMessage: Error display message
//   - showSuccess: Success state trigger
//
// Methods:
//   - sendMessage(eventId:departmentId:): Send message based on recipient type
//   - reset(): Clear form after successful send

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

    var isValid: Bool {
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (recipientType != .volunteer || selectedVolunteerId != nil)
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
                guard let volunteerId = selectedVolunteerId else { return }
                _ = try await MessagesService.shared.sendMessage(
                    volunteerId: volunteerId, subject: subjectText, body: body
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
