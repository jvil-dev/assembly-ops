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
    @Published var postCountHistory: [PostAttendanceHistoryItem] = []
    @Published var myWalkThroughCompletions: [WalkThroughCompletionItem] = []
    @Published var postSessionStatuses: [PostSessionStatusItem] = []
    @Published var facilityLocations: [FacilityLocationItem] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?

    func unresolvedIncidents(for postId: String) -> [SafetyIncidentItem] {
        incidents.filter { $0.postId == postId && !$0.resolved }
    }

    func unresolvedIncidents(forPostIds postIds: Set<String>) -> [SafetyIncidentItem] {
        incidents.filter { postIds.contains($0.postId ?? "") && !$0.resolved }
    }

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

    func loadPostCountHistory(postId: String) async {
        do {
            postCountHistory = try await AttendanceService.shared.fetchPostAttendanceCounts(postId: postId)
        } catch {
            // Non-fatal: history is supplementary
            print("[AttendantVM] Failed to load post count history: \(error)")
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

    // MARK: - Walk-Through Completions

    func submitWalkThrough(eventId: String, sessionId: String, itemCount: Int, notes: String?) async {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let completion = try await AttendantService.shared.submitWalkThroughCompletion(
                eventId: eventId, sessionId: sessionId, itemCount: itemCount, notes: notes
            )
            myWalkThroughCompletions.insert(completion, at: 0)
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    func loadMyWalkThroughCompletions() async {
        do {
            myWalkThroughCompletions = try await AttendantService.shared.fetchMyWalkThroughCompletions()
        } catch {
            print("[AttendantVM] Failed to load walk-through completions: \(error)")
        }
    }

    func hasCompletedWalkThrough(for sessionId: String) -> Bool {
        myWalkThroughCompletions.contains { $0.sessionId == sessionId }
    }

    // MARK: - Post Session Status

    func loadPostSessionStatuses(sessionId: String) async {
        do {
            postSessionStatuses = try await AttendantService.shared.fetchPostSessionStatuses(sessionId: sessionId)
        } catch {
            print("[AttendantVM] Failed to load post session statuses: \(error)")
        }
    }

    func updateSectionStatus(postId: String, sessionId: String, status: SeatingSectionStatusItem) async {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            try await AttendantService.shared.updatePostSessionStatus(
                postId: postId, sessionId: sessionId, status: status.rawValue
            )
            // Update local state
            if let index = postSessionStatuses.firstIndex(where: { $0.postId == postId && $0.sessionId == sessionId }) {
                postSessionStatuses[index].status = status
            }
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    // MARK: - Facility Locations

    func loadFacilityLocations(eventId: String) async {
        do {
            facilityLocations = try await AttendantService.shared.fetchFacilityLocations(eventId: eventId)
        } catch {
            print("[AttendantVM] Failed to load facility locations: \(error)")
        }
    }
}
