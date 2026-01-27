//
//  VolunteerDetailViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Volunteer Detail View Model
//
// Manages volunteer detail actions including removal from department.
//
// Properties:
//   - isLoading: True during async operations
//   - errorMessage: Error text to display (nil on success)
//   - onRemoved: Callback when volunteer is successfully removed
//
// Methods:
//   - removeFromDepartment(): Remove volunteer from their department
//
// Used by: VolunteerDetailView

import Foundation
import Combine
import Apollo

@MainActor
class VolunteerDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let volunteerId: String
    var onRemoved: (() -> Void)?

    init(volunteerId: String) {
        self.volunteerId = volunteerId
    }

    func removeFromDepartment() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await performRemove()
            HapticManager.shared.success()
            onRemoved?()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    private func performRemove() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.RemoveVolunteerFromDepartmentMutation(id: volunteerId)
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(throwing: NetworkError.graphQL(errors.first?.message ?? "Failed to remove"))
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
