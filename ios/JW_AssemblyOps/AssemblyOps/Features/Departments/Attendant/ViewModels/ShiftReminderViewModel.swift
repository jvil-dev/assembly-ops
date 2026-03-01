//
//  ShiftReminderViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Shift Reminder ViewModel
//
// Manages mandatory shift reminder confirmations for attendant volunteers.
// Loads existing confirmations and submits new ones via GraphQL.
//
// Properties:
//   - confirmations: Set of confirmed shiftIds (or sessionIds)
//   - isLoading, error: Standard loading state
//
// Methods:
//   - loadMyConfirmations(eventId:): Fetch existing confirmations
//   - confirmShiftReminder(shiftId:): Confirm for a specific shift
//   - hasConfirmed(shiftId:): Check if a shift reminder was confirmed
//

import Foundation
import Combine

@MainActor
class ShiftReminderViewModel: ObservableObject {
    @Published var confirmedShiftIds: Set<String> = []
    @Published var confirmedSessionIds: Set<String> = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Load Confirmations

    func loadMyConfirmations(eventId: String) async {
        isLoading = true
        error = nil

        do {
            let confirmations = try await AttendantService.shared.fetchMyReminderConfirmations(eventId: eventId)
            confirmedShiftIds = Set(confirmations.compactMap { $0.shiftId })
            confirmedSessionIds = Set(confirmations.compactMap { $0.sessionId })
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Confirm Shift Reminder

    func confirmShiftReminder(shiftId: String) async {
        error = nil

        do {
            try await AttendantService.shared.confirmShiftReminder(shiftId: shiftId)
            confirmedShiftIds.insert(shiftId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Confirm Session Reminder

    func confirmSessionReminder(sessionId: String) async {
        error = nil

        do {
            try await AttendantService.shared.confirmSessionReminder(sessionId: sessionId)
            confirmedSessionIds.insert(sessionId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Check Confirmation

    func hasConfirmed(shiftId: String) -> Bool {
        confirmedShiftIds.contains(shiftId)
    }

    func hasConfirmedSession(sessionId: String) -> Bool {
        confirmedSessionIds.contains(sessionId)
    }
}
