//
//  VolunteerDetailViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Volunteer Detail View Model
//
// Manages volunteer detail actions including removal, token retrieval, and credential regeneration.
//
// Properties:
//   - isLoading: True during async operations
//   - errorMessage: Error text to display (nil on success)
//   - token: Decrypted volunteer token (fetched on demand)
//   - isLoadingToken: True while fetching token
//   - isRegenerating: True while regenerating credentials
//   - regeneratedCredentials: New credentials after regeneration (triggers sheet)
//
// Methods:
//   - removeFromDepartment(): Remove volunteer from their department
//   - fetchToken(): Fetch decrypted token from backend
//   - regenerateCredentials(): Generate new volunteerId + token
//
// Used by: VolunteerDetailView

import Foundation
import Combine
import Apollo

struct RegeneratedCredentials: Identifiable {
    let id = UUID()
    let volunteerId: String
    let token: String
}

@MainActor
class VolunteerDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var token: String?
    @Published var isLoadingToken = false
    @Published var isRegenerating = false
    @Published var regeneratedCredentials: RegeneratedCredentials?

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

    func fetchToken() async {
        isLoadingToken = true
        defer { isLoadingToken = false }

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.VolunteerTokenQuery(id: volunteerId),
                cachePolicy: .fetchIgnoringCacheData
            )

            if let errors = result.errors, !errors.isEmpty {
                errorMessage = errors.first?.message ?? "Failed to fetch token"
                return
            }

            token = result.data?.volunteerToken
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func regenerateCredentials() async {
        isRegenerating = true
        defer { isRegenerating = false }

        do {
            let result = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.RegenerateVolunteerCredentialsMutation(id: volunteerId)
            )

            if let errors = result.errors, !errors.isEmpty {
                errorMessage = errors.first?.message ?? "Failed to regenerate credentials"
                HapticManager.shared.error()
                return
            }

            if let data = result.data?.regenerateVolunteerCredentials {
                regeneratedCredentials = RegeneratedCredentials(
                    volunteerId: data.volunteerId,
                    token: data.token
                )
                token = data.token
                HapticManager.shared.success()
            }
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
