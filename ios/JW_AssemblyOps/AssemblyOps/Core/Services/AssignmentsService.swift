//
//  AssignmentsService.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/15/26.
//

// MARK: - Assignments Service
//
// Service layer for assignment-related GraphQL API calls.
// Extracts network logic from ViewModel for better separation of concerns.
//
// Methods:
//   - fetchAssignments(): Fetch current volunteer's assignments
//   - acceptAssignment(assignmentId:): Accept a pending assignment
//   - declineAssignment(assignmentId:reason:): Decline with optional reason
//   - getCaptainGroup(postId:sessionId:): Get captain's group members
//   - captainCheckIn(assignmentId:notes:): Captain checks in a group member
//
// Dependencies:
//   - NetworkClient: Apollo GraphQL client
//   - Assignment, GroupMember: Local models mapped from GraphQL response
//
// Used by: AssignmentsViewModel, AssignmentDetailViewModel, CaptainGroupViewModel, PendingBadgeManager

import Foundation
import Apollo

final class AssignmentsService {
    static let shared = AssignmentsService()
    
    private init() {}
    
    func fetchAssignments() async throws -> [Assignment] {
        try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.MyAssignmentsQuery(),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.myAssignments {
                        let assignments = data.compactMap { Assignment(from: $0) }
                        continuation.resume(returning: assignments)
                    } else {
                        continuation.resume(returning: [])
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Assignment Acceptance

    /// Accept a pending assignment
    func acceptAssignment(assignmentId: String) async throws {
        let input = AssemblyOpsAPI.AcceptAssignmentInput(assignmentId: assignmentId)

        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.AcceptAssignmentMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to accept assignment"))
                        return
                    }

                    guard graphQLResult.data?.acceptAssignment != nil else {
                        continuation.resume(throwing: NetworkError.noData)
                        return
                    }

                    // Success - caller should refresh full list
                    continuation.resume(returning: ())

                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Decline a pending assignment with optional reason
    func declineAssignment(assignmentId: String, reason: String?) async throws {
        let input = AssemblyOpsAPI.DeclineAssignmentInput(
            assignmentId: assignmentId,
            reason: reason.map { .some($0) } ?? .null
        )

        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeclineAssignmentMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to decline assignment"))
                        return
                    }

                    continuation.resume(returning: ())

                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Captain Features

    /// Get group members for captain at a specific post/session
    func getCaptainGroup(postId: String, sessionId: String) async throws -> [GroupMember] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.CaptainGroupQuery(postId: postId, sessionId: sessionId),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to fetch group"))
                        return
                    }

                    guard let data = graphQLResult.data?.captainGroup else {
                        continuation.resume(returning: [])
                        return
                    }

                    // Map members array (excludes captain)
                    let members = data.members.map { GroupMember(from: $0) }
                    continuation.resume(returning: members)

                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Captain checks in a group member
    func captainCheckIn(assignmentId: String, notes: String?) async throws {
        let input = AssemblyOpsAPI.CaptainCheckInInput(
            assignmentId: assignmentId,
            notes: notes.map { .some($0) } ?? .null
        )

        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CaptainCheckInMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to check in"))
                        return
                    }

                    continuation.resume(returning: ())

                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case graphQL(String)
    case noData
    case unknown

    var errorDescription: String? {
        switch self {
        case .graphQL(let message):
            return message
        case .noData:
            return "No data returned from server"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
