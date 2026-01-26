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
//
// Dependencies:
//   - NetworkClient: Apollo GraphQL client
//   - Assignment: Local model mapped from GraphQL response
//
// Used by: AssignmentsViewModel

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
}
