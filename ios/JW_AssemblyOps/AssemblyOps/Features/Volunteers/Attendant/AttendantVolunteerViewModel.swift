//
//  AttendantVolunteerViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Attendant Volunteer View Model
//
// Manages state for attendant volunteer-facing features.
// Handles count submission, incident reporting, lost person alerts.
//
// Published Properties:
//   - myMeetings: Volunteer's attendant meetings
//   - isLoading / isSaving: Loading states
//   - error: Feedback state
//
// Methods:
//   - loadMyMeetings(eventId:): Fetch attendant meetings
//   - reportIncident(...): Report a safety incident
//   - reportLostPerson(...): Report a lost person
//   - submitPostCount(...): Submit attendance count for a post
//

import Foundation
import Apollo
import Combine

@MainActor
final class AttendantVolunteerViewModel: ObservableObject {
    @Published var myMeetings: [AttendantMeetingItem] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?

    func loadMyMeetings(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            myMeetings = try await AttendantService.shared.fetchMyMeetings(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func reportIncident(eventId: String, type: String, description: String, location: String?, postId: String?, sessionId: String?) async {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            _ = try await AttendantService.shared.reportSafetyIncident(
                eventId: eventId, type: type, description: description,
                location: location, postId: postId, sessionId: sessionId
            )
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    func reportLostPerson(eventId: String, personName: String, age: Int?, description: String,
                          lastSeenLocation: String?, lastSeenTime: String?,
                          contactName: String, contactPhone: String?, sessionId: String?) async {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            _ = try await AttendantService.shared.createLostPersonAlert(
                eventId: eventId, personName: personName, age: age,
                description: description, lastSeenLocation: lastSeenLocation,
                lastSeenTime: lastSeenTime, contactName: contactName,
                contactPhone: contactPhone, sessionId: sessionId
            )
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    func submitPostCount(postId: String, postName: String, sessionId: String, count: Int, notes: String?) async {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            _ = try await AttendanceService.shared.submitAttendanceCount(
                sessionId: sessionId, section: postName, postId: postId, count: count, notes: notes
            )
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}
