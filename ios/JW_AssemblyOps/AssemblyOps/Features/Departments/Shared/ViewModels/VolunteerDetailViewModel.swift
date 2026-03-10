//
//  VolunteerDetailViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Volunteer Detail View Model
//
// Manages volunteer detail actions including removal, updates, and linking.
//
// Used by: VolunteerDetailView, EditVolunteerSheet

import Foundation
import Combine
import Apollo

@MainActor
class VolunteerDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didUpdate = false
    @Published var updatedVolunteer: VolunteerListItem?
    @Published var updateCount = 0
    @Published var didRemove = false

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

    func updateVolunteer(input: AssemblyOpsAPI.UpdateVolunteerInput) async {
        isLoading = true
        didUpdate = false
        defer { isLoading = false }

        do {
            let result = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.UpdateVolunteerMutation(id: volunteerId, input: input)
            )

            if let errors = result.errors, !errors.isEmpty {
                errorMessage = errors.first?.message ?? "Failed to update volunteer"
                HapticManager.shared.error()
                return
            }

            if let updated = result.data?.updateVolunteer {
                updatedVolunteer = VolunteerListItem(
                    id: updated.id,
                    userId: nil,
                    fullName: updated.fullName,
                    firstName: updated.firstName,
                    lastName: updated.lastName,
                    congregation: updated.congregation,
                    phone: updated.phone,
                    email: updated.email,
                    appointmentStatus: updated.appointmentStatus?.rawValue,
                    departmentId: updated.department?.id,
                    departmentName: updated.department?.name,
                    departmentType: updated.department?.departmentType.rawValue,
                    roleId: updated.role?.id,
                    roleName: updated.role?.name,
                    isPlaceholder: updated.isPlaceholder
                )
                didUpdate = true
                updateCount += 1
                HapticManager.shared.success()
            }
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    func linkPlaceholderUser(placeholderUserId: String, realUserId: String) async {
        isLoading = true
        defer { isLoading = false }

        let trimmed = realUserId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmed.count >= 6 else {
            errorMessage = "Please enter a valid 6-character User ID."
            HapticManager.shared.error()
            return
        }

        do {
            let result = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.LinkPlaceholderUserMutation(
                    placeholderUserId: placeholderUserId,
                    realUserId: trimmed
                )
            )

            if let errors = result.errors, !errors.isEmpty {
                errorMessage = errors.first?.message ?? "Failed to link user"
                HapticManager.shared.error()
                return
            }

            if let data = result.data?.linkPlaceholderUser, data.success {
                didRemove = true
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
