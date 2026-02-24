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

struct VolunteerAssignmentItem: Identifiable {
    let id: String
    var isCaptain: Bool
    let status: String
    let postName: String
    let sessionId: String
    let sessionName: String
    let sessionDate: String
}

@MainActor
class VolunteerDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var token: String?
    @Published var isLoadingToken = false
    @Published var isRegenerating = false
    @Published var regeneratedCredentials: RegeneratedCredentials?
    @Published var didUpdate = false
    @Published var updatedVolunteer: VolunteerListItem?
    @Published var updateCount = 0
    @Published var didDelete = false
    @Published var roles: [RoleItem] = []
    @Published var assignments: [VolunteerAssignmentItem] = []
    @Published var isLoadingAssignments = false

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
                    volunteerId: updated.volunteerId,
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
                    roleName: updated.role?.name
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

    func deleteVolunteer() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteVolunteerMutation(id: volunteerId)
            )

            if let errors = result.errors, !errors.isEmpty {
                errorMessage = errors.first?.message ?? "Failed to delete volunteer"
                HapticManager.shared.error()
                return
            }

            didDelete = true
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    func loadRoles(eventId: String) async {
        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.EventRolesQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            )
            if let data = result.data?.roles {
                roles = data.map { RoleItem(id: $0.id, name: $0.name, sortOrder: $0.sortOrder) }
            }
        } catch {
            print("Failed to load roles: \(error)")
        }
    }

    func loadAssignments() async {
        isLoadingAssignments = true
        defer { isLoadingAssignments = false }

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.VolunteerAssignmentsQuery(volunteerId: volunteerId),
                cachePolicy: .fetchIgnoringCacheData
            )

            if let errors = result.errors, !errors.isEmpty {
                errorMessage = errors.first?.message ?? "Failed to load assignments"
                return
            }

            assignments = (result.data?.volunteerAssignments ?? []).map { a in
                VolunteerAssignmentItem(
                    id: a.id,
                    isCaptain: a.isCaptain,
                    status: a.status.rawValue,
                    postName: a.post.name,
                    sessionId: a.session.id,
                    sessionName: a.session.name,
                    sessionDate: {
                        if let date = DateUtils.parseISO8601(a.session.date) {
                            let fmt = DateFormatter()
                            fmt.dateStyle = .medium
                            fmt.timeStyle = .none
                            return fmt.string(from: date)
                        }
                        return a.session.name
                    }()
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setCaptain(assignmentId: String, isCaptain: Bool) async {
        let input = AssemblyOpsAPI.SetCaptainInput(assignmentId: assignmentId, isCaptain: isCaptain)

        do {
            let result = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.SetCaptainMutation(input: input)
            )

            if let errors = result.errors, !errors.isEmpty {
                errorMessage = errors.first?.message ?? "Failed to update captain status"
                HapticManager.shared.error()
                return
            }

            if let updated = result.data?.setCaptain {
                if let idx = assignments.firstIndex(where: { $0.id == updated.id }) {
                    assignments[idx].isCaptain = updated.isCaptain
                }
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
