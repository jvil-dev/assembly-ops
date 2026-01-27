//
//  DeclinedAssignmentsViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Declined Assignments View Model
//
// Manages data loading for the overseer declined assignments view.
// Fetches declined assignments filtered by event and/or department.
//
// Properties:
//   - assignments: Array of declined assignments to display
//   - isLoading: Loading state for UI feedback
//   - errorMessage: Error message if fetch fails
//
// Methods:
//   - load(eventId:departmentId:): Fetch declined assignments with filters
//   - refresh(): Reload with current filters
//
// Used by: DeclinedAssignmentsView

import Foundation
import Apollo
import Combine

@MainActor
class DeclinedAssignmentsViewModel: ObservableObject {
    @Published var assignments: [DeclinedAssignment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var eventId: String?
    private var departmentId: String?

    func load(eventId: String?, departmentId: String?) async {
        self.eventId = eventId
        self.departmentId = departmentId

        isLoading = true
        defer { isLoading = false }

        do {
            assignments = try await fetchDeclinedAssignments()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        await load(eventId: eventId, departmentId: departmentId)
    }

    private func fetchDeclinedAssignments() async throws -> [DeclinedAssignment] {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.DeclinedAssignmentsQuery(
                    eventId: eventId.map { .some($0) } ?? .null,
                    departmentId: departmentId.map { .some($0) } ?? .null
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to fetch"))
                        return
                    }

                    let assignments = graphQLResult.data?.declinedAssignments.map {
                        DeclinedAssignment(from: $0)
                    } ?? []
                    continuation.resume(returning: assignments)

                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
