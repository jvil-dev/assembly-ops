//
//  CheckInService.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 1/2/26.
//

// MARK: - Check-In Service
//
// Service for volunteer check-in/check-out operations via GraphQL mutations.
//
// Methods:
//   - checkIn(assignmentId:): Check in to an assignment, returns CheckInResult
//   - checkOut(assignmentId:): Check out of an assignment, returns CheckInResult
//
// Error Handling:
//   - Throws CheckInError for network, server, or validation errors
//   - Parses GraphQL errors and returns user-friendly messages
//
// Dependencies:
//   - NetworkClient: Apollo GraphQL client for API calls
//   - CheckInStatus: Enum matching backend status values
//
// Used by: AssignmentDetailView (check-in/out actions)

import Foundation
import Apollo

/// Service for check-in/check-out operations
final class CheckInService {
    static let shared = CheckInService()

    private init() {}

    /// Check in to an assignment
    func checkIn(assignmentId: String) async throws -> CheckInResult {
        let input = AssemblyOpsAPI.CheckInInput(assignmentId: assignmentId)

        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CheckInMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.checkIn {
                        let isoFormatter = ISO8601DateFormatter()
                        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                        let checkInResult = CheckInResult(
                            id: data.id,
                            status: CheckInStatus(rawValue: data.status.rawValue) ?? .checkedIn,
                            checkInTime: isoFormatter.date(from: data.checkInTime) ?? Date(),
                            checkOutTime: nil
                        )
                        continuation.resume(returning: checkInResult)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        let message = errors.first?.localizedDescription ?? "Check-in failed"
                        continuation.resume(throwing: CheckInError.serverError(message))
                    } else {
                        continuation.resume(throwing: CheckInError.unknown)
                    }
                case .failure(let error):
                    continuation.resume(throwing: CheckInError.networkError(error.localizedDescription))
                }
            }
        }
    }

    /// Check out of an assignment
    func checkOut(assignmentId: String) async throws -> CheckInResult {
        let input = AssemblyOpsAPI.CheckOutInput(assignmentId: assignmentId)

        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CheckOutMutation(input: input)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.checkOut {
                        let isoFormatter = ISO8601DateFormatter()
                        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                        let checkInResult = CheckInResult(
                            id: data.id,
                            status: CheckInStatus(rawValue: data.status.rawValue) ?? .checkedOut,
                            checkInTime: isoFormatter.date(from: data.checkInTime) ?? Date(),
                            checkOutTime: data.checkOutTime.flatMap { isoFormatter.date(from: $0) }
                        )
                        continuation.resume(returning: checkInResult)
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        let message = errors.first?.localizedDescription ?? "Check-out failed"
                        continuation.resume(throwing: CheckInError.serverError(message))
                    } else {
                        continuation.resume(throwing: CheckInError.unknown)
                    }
                case .failure(let error):
                    continuation.resume(throwing: CheckInError.networkError(error.localizedDescription))
                }
            }
        }
    }
}

/// Result of a check-in/check-out operation
struct CheckInResult {
    let id: String
    let status: CheckInStatus
    let checkInTime: Date
    let checkOutTime: Date?
}

/// Check-in errors
enum CheckInError: LocalizedError {
    case networkError(String)
    case serverError(String)
    case alreadyCheckedIn
    case alreadyCheckedOut
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return message
        case .alreadyCheckedIn:
            return "Already checked in to this assignment"
        case .alreadyCheckedOut:
            return "Already checked out of this assignment"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
