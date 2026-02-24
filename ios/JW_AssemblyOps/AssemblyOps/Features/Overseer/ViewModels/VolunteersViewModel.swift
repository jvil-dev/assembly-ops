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
//   - CreateVolunteerInput: Input data for creating new volunteers
//   - CreatedVolunteerResult: Response containing volunteer info and login credentials
//   - VolunteerListItem: UI model for volunteer display
//
// Methods:
//   - loadDepartmentVolunteers(eventId:departmentId:): Fetch editable department roster
//   - loadAllVolunteers(eventId:): Fetch read-only event-wide roster
//   - loadVolunteers(): Fetch volunteers for picker (uses departmentId property)
//   - createVolunteer(input:): Create new volunteer via CreateVolunteerMutation
//
// Visibility Rules:
//   - Department Overseers: Edit own department, view all read-only
//   - Event Overseers: Full access to all departments
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
        guard let eventId = OverseerSessionState.shared.selectedEvent?.id else {
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

    func createVolunteer(input: CreateVolunteerInput) async -> CreatedVolunteerResult? {
        do {
            let graphQLInput = AssemblyOpsAPI.CreateVolunteerInput(
                firstName: input.firstName,
                lastName: input.lastName,
                email: input.email.flatMap { .some($0) } ?? .none,
                phone: input.phone.flatMap { .some($0) } ?? .none,
                congregation: input.congregation,
                appointmentStatus: mapAppointmentStatus(input.appointmentStatus),
                notes: input.notes.flatMap { .some($0) } ?? .none,
                departmentId: .some(input.departmentId),
                roleId: input.roleId.map { .some($0) } ?? .none
            )

            let result = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.CreateVolunteerMutation(
                    eventId: input.eventId,
                    input: graphQLInput
                )
            )

            guard let data = result.data?.createVolunteer else {
                return nil
            }

            let selectedRole = roles.first { $0.id == input.roleId }
            let newVolunteer = VolunteerListItem(
                id: data.id,
                volunteerId: data.volunteerId,
                fullName: "\(data.firstName) \(data.lastName)",
                firstName: data.firstName,
                lastName: data.lastName,
                congregation: data.congregation,
                phone: nil,
                email: nil,
                appointmentStatus: input.appointmentStatus,
                departmentId: input.departmentId,
                departmentName: nil,
                departmentType: nil,
                roleId: input.roleId,
                roleName: selectedRole?.name
            )

            // Add to department volunteers list
            departmentVolunteers.append(newVolunteer)

            return CreatedVolunteerResult(
                volunteer: newVolunteer,
                volunteerId: data.volunteerId,
                token: data.token
            )
        } catch {
            self.error = "Failed to create volunteer: \(error.localizedDescription)"
            return nil
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

    private func mapAppointmentStatus(_ status: String) -> GraphQLNullable<GraphQLEnum<AssemblyOpsAPI.AppointmentStatus>> {
        switch status {
        case "PUBLISHER":
            return .some(.case(.publisher))
        case "MINISTERIAL_SERVANT":
            return .some(.case(.ministerialServant))
        case "ELDER":
            return .some(.case(.elder))
        default:
            return .none
        }
    }
}

struct CreateVolunteerInput {
    let firstName: String
    let lastName: String
    let congregation: String
    let phone: String?
    let email: String?
    let appointmentStatus: String
    let notes: String?
    let departmentId: String
    let eventId: String
    let roleId: String?
}

struct CreatedVolunteerResult {
    let volunteer: VolunteerListItem
    let volunteerId: String
    let token: String
}
