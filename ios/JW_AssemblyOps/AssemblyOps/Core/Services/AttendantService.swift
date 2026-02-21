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
    func createMeeting(eventId: String, sessionId: String, meetingDate: String, notes: String?, attendeeIds: [String]) async throws -> AttendantMeetingItem {
        let input = AssemblyOpsAPI.CreateAttendantMeetingInput(
            eventId: eventId,
            sessionId: sessionId,
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
}
