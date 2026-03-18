//
//  AttendantService.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Attendant Service
//
// Handles all attendant department GraphQL API calls.
// Manages safety incidents, lost person alerts, and meetings.
//
// Methods:
//   - fetchSafetyIncidents(eventId:resolved:): Get incidents with optional filter
//   - reportSafetyIncident(...): Report a new safety incident
//   - resolveSafetyIncident(id:resolutionNotes:): Mark incident resolved
//   - fetchLostPersonAlerts(eventId:resolved:): Get alerts with optional filter
//   - createLostPersonAlert(...): Report a lost person
//   - resolveLostPersonAlert(id:resolutionNotes:): Mark alert resolved
//   - fetchMeetings(eventId:): Get all attendant meetings
//   - createMeeting(eventId:sessionId:meetingDate:notes:attendeeIds:): Create meeting
//   - updateMeeting(id:meetingDate:notes:attendeeIds:): Update meeting
//   - fetchMyMeetings(eventId:): Get volunteer's meetings
//
// Dependencies:
//   - NetworkClient: Apollo client for GraphQL

import Foundation
import Apollo

enum AttendantError: LocalizedError {
    case networkError(String)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message): return "Network error: \(message)"
        case .serverError(let message): return message
        }
    }
}

/// Service for attendant department operations
final class AttendantService {
    static let shared = AttendantService()

    private init() {}

    // MARK: - Safety Incidents

    /// Fetch safety incidents for an event
    func fetchSafetyIncidents(eventId: String, resolved: Bool?) async throws -> [SafetyIncidentItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.SafetyIncidentsQuery(
                    eventId: eventId,
                    resolved: resolved.map { .some($0) } ?? .none
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.safetyIncidents {
                        let incidents = data.compactMap { SafetyIncidentItem(from: $0) }
                        continuation.resume(returning: incidents)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Report a safety incident
    func reportSafetyIncident(eventId: String, type: String, description: String, location: String?, postId: String?, sessionId: String?) async throws -> SafetyIncidentItem {
        let input = AssemblyOpsAPI.ReportSafetyIncidentInput(
            eventId: eventId,
            type: .init(rawValue: type),
            description: description,
            location: location.map { .some($0) } ?? .none,
            postId: postId.map { .some($0) } ?? .none,
            sessionId: sessionId.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.ReportSafetyIncidentMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.reportSafetyIncident,
                       let item = SafetyIncidentItem(fromReport: data) {
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to report incident"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Resolve a safety incident
    func resolveSafetyIncident(id: String, resolutionNotes: String?) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.ResolveSafetyIncidentMutation(
                    id: id,
                    resolutionNotes: resolutionNotes.map { .some($0) } ?? .none
                )
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.resolveSafetyIncident != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to resolve incident"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Lost Person Alerts

    /// Fetch lost person alerts for an event
    func fetchLostPersonAlerts(eventId: String, resolved: Bool?) async throws -> [LostPersonAlertItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.LostPersonAlertsQuery(
                    eventId: eventId,
                    resolved: resolved.map { .some($0) } ?? .none
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.lostPersonAlerts {
                        let alerts = data.compactMap { LostPersonAlertItem(from: $0) }
                        continuation.resume(returning: alerts)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Create a lost person alert
    func createLostPersonAlert(eventId: String, personName: String, age: Int?, description: String,
                               lastSeenLocation: String?, lastSeenTime: String?,
                               contactName: String, contactPhone: String?, sessionId: String?) async throws -> LostPersonAlertItem {
        let input = AssemblyOpsAPI.CreateLostPersonAlertInput(
            eventId: eventId,
            personName: personName,
            age: age.map { .some($0) } ?? .none,
            description: description,
            lastSeenLocation: lastSeenLocation.map { .some($0) } ?? .none,
            lastSeenTime: lastSeenTime.map { .some($0) } ?? .none,
            contactName: contactName,
            contactPhone: contactPhone.map { .some($0) } ?? .none,
            sessionId: sessionId.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CreateLostPersonAlertMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.createLostPersonAlert,
                       let item = LostPersonAlertItem(fromCreate: data) {
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to create alert"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Resolve a lost person alert
    func resolveLostPersonAlert(id: String, resolutionNotes: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.ResolveLostPersonAlertMutation(
                    id: id,
                    resolutionNotes: resolutionNotes
                )
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.resolveLostPersonAlert != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to resolve alert"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Meetings

    /// Fetch all attendant meetings for an event
    func fetchMeetings(eventId: String) async throws -> [AttendantMeetingItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.AttendantMeetingsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.attendantMeetings {
                        let meetings = data.compactMap { AttendantMeetingItem(from: $0) }
                        continuation.resume(returning: meetings)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Create a new attendant meeting
    func createMeeting(eventId: String, sessionId: String, name: String?, meetingDate: String, notes: String?, attendeeIds: [String]) async throws -> AttendantMeetingItem {
        let input = AssemblyOpsAPI.CreateAttendantMeetingInput(
            eventId: eventId,
            sessionId: sessionId,
            name: name.map { .some($0) } ?? .none,
            meetingDate: meetingDate,
            notes: notes.map { .some($0) } ?? .none,
            attendeeIds: attendeeIds
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CreateAttendantMeetingMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.createAttendantMeeting,
                       let item = AttendantMeetingItem(fromCreate: data) {
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to create meeting"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Update an attendant meeting (date, notes, and/or attendees)
    func updateMeeting(id: String, name: String?, meetingDate: String?, notes: String?, attendeeIds: [String]?) async throws -> AttendantMeetingItem {
        let input = AssemblyOpsAPI.UpdateAttendantMeetingInput(
            id: id,
            name: name.map { .some($0) } ?? .none,
            meetingDate: meetingDate.map { .some($0) } ?? .none,
            notes: notes.map { .some($0) } ?? .none,
            attendeeIds: attendeeIds.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpdateAttendantMeetingMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.updateAttendantMeeting,
                       let item = AttendantMeetingItem(fromUpdate: data) {
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to update meeting"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Walk-Through Completions

    func submitWalkThroughCompletion(eventId: String, sessionId: String, itemCount: Int, notes: String?) async throws -> WalkThroughCompletionItem {
        let input = AssemblyOpsAPI.SubmitWalkThroughCompletionInput(
            eventId: eventId,
            sessionId: sessionId,
            itemCount: itemCount,
            notes: notes.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.SubmitWalkThroughCompletionMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.submitWalkThroughCompletion {
                        let item = WalkThroughCompletionItem(
                            id: data.id, sessionId: data.session.id, sessionName: data.session.name,
                            completedAt: DateUtils.parseISO8601(data.completedAt) ?? Date(),
                            itemCount: data.itemCount, notes: data.notes, volunteerName: nil
                        )
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to submit walk-through"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    func fetchMyWalkThroughCompletions() async throws -> [WalkThroughCompletionItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyWalkThroughCompletionsQuery(),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.myWalkThroughCompletions {
                        continuation.resume(returning: data.compactMap { WalkThroughCompletionItem(fromMy: $0) })
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    func fetchWalkThroughCompletions(eventId: String, sessionId: String?) async throws -> [WalkThroughCompletionItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.WalkThroughCompletionsQuery(
                    eventId: eventId, sessionId: sessionId.map { .some($0) } ?? .none
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.walkThroughCompletions {
                        continuation.resume(returning: data.compactMap { WalkThroughCompletionItem(fromAdmin: $0) })
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Post Session Status

    func fetchPostSessionStatuses(sessionId: String) async throws -> [PostSessionStatusItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.PostSessionStatusesQuery(sessionId: sessionId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.postSessionStatuses {
                        continuation.resume(returning: data.compactMap { PostSessionStatusItem(from: $0) })
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    func updatePostSessionStatus(postId: String, sessionId: String, status: String) async throws {
        let input = AssemblyOpsAPI.UpdatePostSessionStatusInput(
            postId: postId, sessionId: sessionId, status: .init(rawValue: status)
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpdatePostSessionStatusMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.updatePostSessionStatus != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to update status"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Shifts

    /// Fetch shifts for a session, optionally filtered by post
    func fetchShifts(sessionId: String, postId: String? = nil) async throws -> [ShiftItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.ShiftsQuery(
                    sessionId: sessionId,
                    postId: postId.map { .some($0) } ?? .none
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.shifts {
                        let shifts = data.map { ShiftItem(from: $0) }
                        continuation.resume(returning: shifts)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Create a new shift for a specific post within a session (name auto-generated by backend)
    func createShift(sessionId: String, postId: String, startTime: String, endTime: String) async throws -> ShiftItem {
        let input = AssemblyOpsAPI.CreateShiftInput(
            sessionId: sessionId,
            postId: postId,
            startTime: startTime,
            endTime: endTime
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CreateShiftMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.createShift {
                        let item = ShiftItem(fromCreate: data)
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to create shift"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Update an existing shift (name auto-generated by backend from times)
    func updateShift(id: String, startTime: String?, endTime: String?) async throws -> ShiftItem {
        let input = AssemblyOpsAPI.UpdateShiftInput(
            startTime: startTime.map { .some($0) } ?? .none,
            endTime: endTime.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpdateShiftMutation(id: id, input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.updateShift {
                        let item = ShiftItem(fromUpdate: data)
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to update shift"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Delete a shift
    func deleteShift(id: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteShiftMutation(id: id)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.deleteShift != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to delete shift"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Reminder Confirmations

    /// Fetch the current volunteer's reminder confirmations for an event
    func fetchMyReminderConfirmations(eventId: String) async throws -> [ReminderConfirmationItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyReminderConfirmationsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.myReminderConfirmations {
                        let items = data.map { ReminderConfirmationItem(from: $0) }
                        continuation.resume(returning: items)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Confirm a shift reminder
    func confirmShiftReminder(shiftId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.ConfirmShiftReminderMutation(shiftId: shiftId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.confirmShiftReminder != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to confirm reminder"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Confirm a session reminder (fallback for non-shift departments)
    func confirmSessionReminder(sessionId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.ConfirmSessionReminderMutation(sessionId: sessionId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.confirmSessionReminder != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to confirm reminder"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch shift reminder compliance status (overseer)
    func fetchShiftReminderStatus(shiftId: String) async throws -> ComplianceData {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.ShiftReminderStatusQuery(shiftId: shiftId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.shiftReminderStatus {
                        let volunteers = data.confirmations.map { vol in
                            VolunteerComplianceStatus(
                                eventVolunteerId: vol.eventVolunteerId,
                                firstName: vol.firstName,
                                lastName: vol.lastName,
                                confirmed: vol.confirmed,
                                confirmedAt: vol.confirmedAt
                            )
                        }
                        let compliance = ComplianceData(
                            shiftId: data.shiftId,
                            shiftName: data.shiftName,
                            totalAssigned: data.totalAssigned,
                            totalConfirmed: data.totalConfirmed,
                            volunteers: volunteers
                        )
                        continuation.resume(returning: compliance)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to load compliance data"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Lanyard Tracking

    /// Fetch the current volunteer's lanyard status for today
    func fetchMyLanyardStatus(eventId: String) async throws -> LanyardStatusItem? {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyLanyardStatusQuery(eventId: eventId, date: .none),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.myLanyardStatus {
                        let item = LanyardStatusItem(
                            id: data.id,
                            eventVolunteerId: data.eventVolunteerId,
                            date: data.date,
                            pickedUpAt: data.pickedUpAt,
                            returnedAt: data.returnedAt,
                            volunteerName: data.volunteerName
                        )
                        continuation.resume(returning: item)
                    } else {
                        continuation.resume(returning: nil)
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Pick up lanyard
    func pickUpLanyard(eventId: String) async throws -> LanyardStatusItem {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.PickUpLanyardMutation(eventId: eventId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.pickUpLanyard {
                        let item = LanyardStatusItem(
                            id: data.id,
                            eventVolunteerId: data.eventVolunteerId,
                            date: data.date,
                            pickedUpAt: data.pickedUpAt,
                            returnedAt: data.returnedAt,
                            volunteerName: data.volunteerName
                        )
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to pick up lanyard"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Return lanyard
    func returnLanyard(eventId: String) async throws -> LanyardStatusItem {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.ReturnLanyardMutation(eventId: eventId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.returnLanyard {
                        let item = LanyardStatusItem(
                            id: data.id,
                            eventVolunteerId: data.eventVolunteerId,
                            date: data.date,
                            pickedUpAt: data.pickedUpAt,
                            returnedAt: data.returnedAt,
                            volunteerName: data.volunteerName
                        )
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to return lanyard"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch all volunteers' lanyard statuses (overseer)
    func fetchLanyardStatuses(eventId: String) async throws -> [LanyardStatusItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.LanyardStatusesQuery(eventId: eventId, date: .none),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.lanyardStatuses {
                        let items = data.map { status in
                            LanyardStatusItem(
                                id: status.id,
                                eventVolunteerId: status.eventVolunteerId,
                                date: status.date,
                                pickedUpAt: status.pickedUpAt,
                                returnedAt: status.returnedAt,
                                volunteerName: status.volunteerName
                            )
                        }
                        continuation.resume(returning: items)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch lanyard summary (overseer)
    func fetchLanyardSummary(eventId: String) async throws -> LanyardSummaryItem {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.LanyardSummaryQuery(eventId: eventId, date: .none),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.lanyardSummary {
                        let summary = LanyardSummaryItem(
                            total: data.total,
                            pickedUp: data.pickedUp,
                            returned: data.returned,
                            notPickedUp: data.notPickedUp
                        )
                        continuation.resume(returning: summary)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to load summary"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Overseer marks pickup for a volunteer
    func overseerPickUpLanyard(eventVolunteerId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.OverseerPickUpLanyardMutation(eventVolunteerId: eventVolunteerId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.overseerPickUpLanyard != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to mark pickup"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Overseer marks return for a volunteer
    func overseerReturnLanyard(eventVolunteerId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.OverseerReturnLanyardMutation(eventVolunteerId: eventVolunteerId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.overseerReturnLanyard != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to mark return"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Volunteer resets own lanyard status
    func resetLanyard(eventId: String) async throws -> LanyardStatusItem {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.ResetLanyardMutation(eventId: eventId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.resetLanyard {
                        let item = LanyardStatusItem(
                            id: data.id,
                            eventVolunteerId: data.eventVolunteerId,
                            date: data.date,
                            pickedUpAt: data.pickedUpAt,
                            returnedAt: data.returnedAt,
                            volunteerName: data.volunteerName
                        )
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to reset lanyard"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Overseer resets lanyard status for a volunteer
    func overseerResetLanyard(eventVolunteerId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.OverseerResetLanyardMutation(eventVolunteerId: eventVolunteerId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.overseerResetLanyard != nil {
                        continuation.resume()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendantError.serverError("Failed to reset lanyard"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Volunteer Meetings

    /// Fetch meetings the current volunteer is assigned to
    func fetchMyMeetings(eventId: String) async throws -> [AttendantMeetingItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyAttendantMeetingsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.myAttendantMeetings {
                        let meetings = data.compactMap { AttendantMeetingItem(fromMyMeeting: $0) }
                        continuation.resume(returning: meetings)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - My Attendance Status

    struct AttendanceStatusItem {
        let sessionId: String
        let sessionName: String
        let sessionDate: Date
        let sessionStartTime: Date
        let sessionEndTime: Date
        let hasSubmitted: Bool
        let postId: String?
        let postName: String?
    }

    func fetchMyAttendanceStatus(eventId: String) async throws -> [AttendanceStatusItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyAttendanceStatusQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.myAttendanceStatus {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        let fallback = ISO8601DateFormatter()

                        func parseDate(_ str: String) -> Date {
                            formatter.date(from: str) ?? fallback.date(from: str) ?? Date()
                        }

                        let items = data.map { item in
                            AttendanceStatusItem(
                                sessionId: item.session.id,
                                sessionName: item.session.name,
                                sessionDate: parseDate(item.session.date),
                                sessionStartTime: parseDate(item.session.startTime),
                                sessionEndTime: parseDate(item.session.endTime),
                                hasSubmitted: item.hasSubmitted,
                                postId: item.postId,
                                postName: item.postName
                            )
                        }
                        continuation.resume(returning: items)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendantError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendantError.networkError(error.localizedDescription))
                }
            }
        }
    }
}
