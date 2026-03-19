//
//  AttendantMeetingViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Attendant Meeting View Model
//
// Manages state for meeting list and creation.
// Used by AttendantMeetingsView and CreateMeetingSheet.
//
// Published Properties:
//   - meetings: All meetings for the event
//   - isLoading / isSaving: Loading states
//   - error: Error state
//   - didCreate / didUpdate: Success flags for sheet dismissal
//
// Methods:
//   - loadMeetings(eventId:): Fetch all meetings
//   - createMeeting(...): Create meeting with attendees
//   - updateMeeting(...): Update meeting date, notes, and/or attendees
//

import Foundation
import Apollo
import Combine

@MainActor
final class AttendantMeetingViewModel: ObservableObject {
    @Published var meetings: [AttendantMeetingItem] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var didCreate = false
    @Published var didUpdate = false

    func loadMeetings(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            meetings = try await AttendantService.shared.fetchMeetings(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createMeeting(eventId: String, sessionId: String, name: String?, meetingDate: String, notes: String?, attendeeIds: [String]) async {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            _ = try await AttendantService.shared.createMeeting(
                eventId: eventId, sessionId: sessionId, name: name,
                meetingDate: meetingDate, notes: notes, attendeeIds: attendeeIds
            )
            HapticManager.shared.success()
            didCreate = true
            await loadMeetings(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    func updateMeeting(id: String, eventId: String, name: String?, meetingDate: String?, notes: String?, attendeeIds: [String]?) async {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            _ = try await AttendantService.shared.updateMeeting(
                id: id, name: name, meetingDate: meetingDate, notes: notes, attendeeIds: attendeeIds
            )
            HapticManager.shared.success()
            didUpdate = true
            await loadMeetings(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}
