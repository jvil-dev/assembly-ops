//
//  VolunteersViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Volunteers View Model
//
// Manages volunteer data for overseer list views and picker sheets.
// Supports department-scoped and event-wide volunteer queries.
//
// Properties:
//   - departmentVolunteers: Volunteers in the overseer's department (editable)
//   - allVolunteers: All event volunteers (read-only cross-department view)
//   - volunteers: Volunteer list for VolunteerPickerSheet
//   - departmentId: Target department for picker queries
//
// Types:
//   - AddedVolunteerResult: Response containing volunteer info and login credentials
//   - VolunteerListItem: UI model for volunteer display
//
// Methods:
//   - loadDepartmentVolunteers(eventId:departmentId:): Fetch editable department roster
//   - loadAllVolunteers(eventId:): Fetch read-only event-wide roster
//   - loadVolunteers(): Fetch volunteers for picker (uses departmentId property)
//   - addVolunteerByUserId(userId:): Add an existing user to event by their 6-char User ID
//
// Visibility Rules:
//   - Department Overseers: Edit own department, view all read-only
//

import Foundation
import Combine
import Apollo

@MainActor
final class VolunteersViewModel: ObservableObject {
    @Published var departmentVolunteers: [VolunteerListItem] = []
    @Published var allVolunteers: [VolunteerListItem] = []
    @Published var volunteers: [VolunteerListItem] = [] // For VolunteerPickerSheet
    @Published var roles: [RoleItem] = []
    @Published var isLoading = false
    @Published var isAddingVolunteer = false
    @Published var addedVolunteerCredentials: AddedVolunteerResult?
    @Published var error: String?

    var departmentId: String?

    /// Load volunteers for a specific department (editable)
    func loadDepartmentVolunteers(eventId: String, departmentId: String?) async {
        guard let departmentId = departmentId else {
            departmentVolunteers = []
            return
        }

        isLoading = true
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.VolunteersQuery(
                    eventId: eventId,
                    departmentId: .some(departmentId)
                ),
                cachePolicy: .fetchIgnoringCacheData
            )

            guard let data = result.data?.volunteers else {
                error = "Failed to load volunteers"
                isLoading = false
                return
            }

            departmentVolunteers = data.map { mapToVolunteerListItem($0) }
        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Load all volunteers for the event (read-only cross-department view)
    func loadAllVolunteers(eventId: String) async {
        isLoading = true
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.VolunteersQuery(
                    eventId: eventId,
                    departmentId: .none
                ),
                cachePolicy: .fetchIgnoringCacheData
            )

            guard let data = result.data?.volunteers else {
                error = "Failed to load volunteers"
                isLoading = false
                return
            }

            allVolunteers = data.map { mapToVolunteerListItem($0) }
        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Load volunteers for VolunteerPickerSheet (uses departmentId property)
    func loadVolunteers() async {
        guard let departmentId = departmentId else {
            volunteers = []
            return
        }

        // Get eventId from session state
        guard let eventId = EventSessionState.shared.selectedEvent?.id else {
            volunteers = []
            return
        }

        isLoading = true

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.VolunteersQuery(
                    eventId: eventId,
                    departmentId: .some(departmentId)
                ),
                cachePolicy: .fetchIgnoringCacheData
            )

            if let data = result.data?.volunteers {
                volunteers = data.map { mapToVolunteerListItem($0) }
            }
        } catch {
            print("Failed to load volunteers: \(error)")
        }

        isLoading = false
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

    /// Add an existing user to the event by their 6-char User ID (primary overseer flow)
    func addVolunteerByUserId(userId: String) async {
        guard let eventId = EventSessionState.shared.selectedEvent?.id else {
            error = "No active event selected."
            return
        }

        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else {
            error = "Please enter a User ID."
            return
        }

        isAddingVolunteer = true
        error = nil

        let deptId: GraphQLNullable<String>
        if let dept = EventSessionState.shared.claimedDepartment?.id {
            deptId = .some(dept)
        } else {
            deptId = .none
        }

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.AddVolunteerByUserIdMutation(
                eventId: eventId,
                userId: trimmed,
                departmentId: deptId
            )
        ) { [weak self] result in
            Task { @MainActor in
                self?.isAddingVolunteer = false
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.addVolunteerByUserId {
                        let ev = data.eventVolunteer
                        let user = ev.user
                        let fullName = "\(user.firstName) \(user.lastName)"
                        self?.addedVolunteerCredentials = AddedVolunteerResult(
                            name: fullName,
                            volunteerId: data.volunteerId,
                            token: data.token,
                            inviteMessage: data.inviteMessage
                        )
                        // Append to department roster immediately
                        let newItem = VolunteerListItem(
                            id: ev.id,
                            volunteerId: data.volunteerId,
                            fullName: fullName,
                            firstName: user.firstName,
                            lastName: user.lastName,
                            congregation: "",
                            phone: nil,
                            email: nil,
                            appointmentStatus: nil,
                            departmentId: self?.departmentId,
                            departmentName: nil,
                            departmentType: nil,
                            roleId: nil,
                            roleName: nil
                        )
                        self?.departmentVolunteers.append(newItem)
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.error = errors.first?.message ?? "Failed to add volunteer"
                        HapticManager.shared.error()
                    }
                case .failure(let err):
                    self?.error = err.localizedDescription
                    HapticManager.shared.error()
                }
            }
        }
    }

    /// Delete a volunteer permanently
    func deleteVolunteer(id: String) async -> Bool {
        do {
            let result = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteVolunteerMutation(id: id)
            )

            if let errors = result.errors, !errors.isEmpty {
                self.error = errors.first?.message ?? "Failed to delete volunteer"
                return false
            }

            // Remove from local arrays
            departmentVolunteers.removeAll { $0.id == id }
            allVolunteers.removeAll { $0.id == id }
            volunteers.removeAll { $0.id == id }
            return true
        } catch {
            self.error = "Failed to delete volunteer: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Helpers

    private func mapToVolunteerListItem(_ volunteer: AssemblyOpsAPI.VolunteersQuery.Data.Volunteer) -> VolunteerListItem {
        VolunteerListItem(
            id: volunteer.id,
            volunteerId: volunteer.volunteerId,
            fullName: volunteer.fullName,
            firstName: volunteer.firstName,
            lastName: volunteer.lastName,
            congregation: volunteer.congregation,
            phone: volunteer.phone,
            email: volunteer.email,
            appointmentStatus: volunteer.appointmentStatus?.rawValue,
            departmentId: volunteer.department?.id,
            departmentName: volunteer.department?.name,
            departmentType: volunteer.department?.departmentType.rawValue,
            roleId: volunteer.role?.id,
            roleName: volunteer.role?.name
        )
    }
}

struct AddedVolunteerResult: Identifiable {
    let id = UUID()
    let name: String
    let volunteerId: String
    let token: String
    let inviteMessage: String?
}
