//
//  AttendanceService.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Attendance Service
//
// Handles all attendance-related GraphQL API calls.
// Manages both attendance count submissions and check-in statistics queries.
//
// Methods:
//   - submitAttendanceCount(sessionId:count:section:notes:): Submit new attendance count for session
//   - updateAttendanceCount(countId:count:section:notes:): Update existing attendance count
//   - deleteAttendanceCount(countId:): Delete attendance count
//   - fetchSessionAttendanceCounts(sessionId:): Get all counts for a session
//   - fetchEventAttendanceSummary(eventId:): Get attendance summary across all sessions
//   - fetchCheckInStats(eventId:departmentId:): Get check-in statistics for event/department
//
// Dependencies:
//   - NetworkClient: Apollo client for GraphQL

import Foundation
import Apollo

enum AttendanceError: LocalizedError {
    case networkError(String)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message): return "Network error: \(message)"
        case .serverError(let message): return message
        }
    }
}


/// Service for attendance count operations
final class AttendanceService {
    static let shared = AttendanceService()
    
    private init() {}
    
    // MARK: - Queries
    
    /// Fetch attendance summary for all sessions in an event
    func fetchEventAttendanceSummary(eventId: String) async throws -> [SessionAttendanceSummaryItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.EventAttendanceSummaryQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.eventAttendanceSummary {
                        let summaries = data.compactMap { SessionAttendanceSummaryItem(from: $0) }
                        continuation.resume(returning: summaries)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendanceError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendanceError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch attendance counts for a specific session
    func fetchSessionAttendanceCounts(sessionId: String) async throws -> [AttendanceCountItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.SessionAttendanceCountsQuery(sessionId: sessionId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.sessionAttendanceCounts {
                        let counts = data.compactMap { AttendanceCountItem(from: $0) }
                        continuation.resume(returning: counts)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendanceError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendanceError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Fetch posts for a department (used to populate section picker for Attendant dept)
    func fetchAttendantPosts(departmentId: String) async throws -> [AttendantPostItem] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.AttendantPostsQuery(departmentId: departmentId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.posts {
                        let posts = data.map { AttendantPostItem(from: $0) }
                        continuation.resume(returning: posts)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendanceError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendanceError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Mutations

    /// Submit attendance count for a session/post (upserts on same session+section)
    func submitAttendanceCount(sessionId: String, section: String?, postId: String? = nil, count: Int, notes: String?) async throws -> AttendanceCountItem {
        let input = AssemblyOpsAPI.SubmitAttendanceCountInput(
            sessionId: sessionId,
            section: section.map { .some($0) } ?? .none,
            postId: postId.map { .some($0) } ?? .none,
            count: count,
            notes: notes.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.SubmitAttendanceCountMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.submitAttendanceCount,
                       let item = AttendanceCountItem(from: data) {
                        continuation.resume(returning: item)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendanceError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(throwing: AttendanceError.serverError("Failed to submit count"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendanceError.networkError(error.localizedDescription))
                }
            }
        }
    }

    func updateAttendanceCount(id: String, count: Int?, notes: String?) async throws -> AttendanceCountItem {
        let input = AssemblyOpsAPI.UpdateAttendanceCountInput(
            count: count.map { .some($0) } ?? .none,
            notes: notes.map { .some($0) } ?? .none
        )
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpdateAttendanceCountMutation(id: id, input: input)
            ) { result in
                // ... same pattern as above
            }
        }
    }

    func deleteAttendanceCount(id: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteAttendanceCountMutation(id: id)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let deleted = graphQLResult.data?.deleteAttendanceCount {
                        continuation.resume(returning: deleted)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: AttendanceError.serverError(errors.first?.localizedDescription ?? "Unknown error"))
                    } else {
                        continuation.resume(returning: false)
                    }
                case .failure(let error):
                    continuation.resume(throwing: AttendanceError.networkError(error.localizedDescription))
                }
            }
        }
    }
}
