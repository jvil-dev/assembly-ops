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
//   - incidents: All safety incidents for the event
//   - alerts: All lost person alerts for the event
//   - isLoading / isSaving: Loading states
//   - error: Feedback state
//
// Methods:
//   - loadMyMeetings(eventId:): Fetch attendant meetings
//   - loadConcerns(eventId:): Fetch incidents + alerts in parallel
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
    @Published var incidents: [SafetyIncidentItem] = []
    @Published var alerts: [LostPersonAlertItem] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?

    var concerns: [ConcernItem] {
        (incidents.map { .incident($0) } + alerts.map { .alert($0) })
            .sorted { $0.createdAt > $1.createdAt }
    }

    func loadConcerns(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            async let fetchedIncidents = AttendantService.shared.fetchSafetyIncidents(eventId: eventId, resolved: nil)
            async let fetchedAlerts = AttendantService.shared.fetchLostPersonAlerts(eventId: eventId, resolved: nil)
            (incidents, alerts) = try await (fetchedIncidents, fetchedAlerts)
        } catch {
            self.error = error.localizedDescription
        }
    }

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
