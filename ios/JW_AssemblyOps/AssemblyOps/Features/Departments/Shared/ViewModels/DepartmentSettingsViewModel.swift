//
//  DepartmentSettingsViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/25/26.
//

// MARK: - Department Settings ViewModel
//
// Loads full department info and manages department-level settings:
//   - Privacy toggle (isPublic)
//   - Hierarchy role assignment (Assistant Overseer)
//   - Access code display
//
// Data: DepartmentInfoQuery, SetDepartmentPrivacyMutation,
//       AssignHierarchyRoleMutation, RemoveHierarchyRoleMutation

import Foundation
import Combine
import Apollo

@MainActor
final class DepartmentSettingsViewModel: ObservableObject {
    @Published var departmentInfo: DepartmentDetail?
    @Published var isLoading = false
    @Published var isSavingPrivacy = false
    @Published var isAssigningRole = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    struct DepartmentDetail {
        let id: String
        let name: String
        let departmentType: String
        let accessCode: String?
        var isPublic: Bool
        let eventId: String
        let eventName: String
        let eventType: String
        let venue: String
        let startDate: String
        let endDate: String
        let overseerName: String?
        var hierarchyRoles: [HierarchyRoleItem]
        let volunteerCount: Int
    }

    struct HierarchyRoleItem: Identifiable {
        let id: String
        let role: String
        let volunteerName: String
        let eventVolunteerId: String
        let assignedAt: String
    }

    func reload(departmentId: String) async {
        await withCheckedContinuation { continuation in
            isLoading = true
            errorMessage = nil
            NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.DepartmentInfoQuery(departmentId: departmentId),
                cachePolicy: .fetchIgnoringCacheData
            ) { [weak self] result in
                Task { @MainActor in
                    self?.isLoading = false
                    if case .success(let graphQLResult) = result,
                       let dept = graphQLResult.data?.departmentInfo {
                        self?.departmentInfo = DepartmentDetail(
                            id: dept.id,
                            name: dept.name,
                            departmentType: dept.departmentType.rawValue,
                            accessCode: dept.accessCode,
                            isPublic: dept.isPublic,
                            eventId: dept.event.id,
                            eventName: dept.event.name,
                            eventType: dept.event.eventType.rawValue,
                            venue: dept.event.venue,
                            startDate: dept.event.startDate,
                            endDate: dept.event.endDate,
                            overseerName: dept.overseer.map { "\($0.user.firstName) \($0.user.lastName)" },
                            hierarchyRoles: dept.hierarchyRoles.map { hr in
                                HierarchyRoleItem(
                                    id: hr.id,
                                    role: hr.hierarchyRole.rawValue,
                                    volunteerName: "\(hr.eventVolunteer.firstName) \(hr.eventVolunteer.lastName)",
                                    eventVolunteerId: hr.eventVolunteer.id,
                                    assignedAt: hr.assignedAt
                                )
                            },
                            volunteerCount: dept.volunteerCount
                        )
                    }
                    continuation.resume()
                }
            }
        }
    }

    func load(departmentId: String) {
        isLoading = true
        errorMessage = nil

        NetworkClient.shared.apollo.fetch(
            query: AssemblyOpsAPI.DepartmentInfoQuery(departmentId: departmentId),
            cachePolicy: .fetchIgnoringCacheData
        ) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                switch result {
                case .success(let graphQLResult):
                    if let dept = graphQLResult.data?.departmentInfo {
                        self?.departmentInfo = DepartmentDetail(
                            id: dept.id,
                            name: dept.name,
                            departmentType: dept.departmentType.rawValue,
                            accessCode: dept.accessCode,
                            isPublic: dept.isPublic,
                            eventId: dept.event.id,
                            eventName: dept.event.name,
                            eventType: dept.event.eventType.rawValue,
                            venue: dept.event.venue,
                            startDate: dept.event.startDate,
                            endDate: dept.event.endDate,
                            overseerName: dept.overseer.map { "\($0.user.firstName) \($0.user.lastName)" },
                            hierarchyRoles: dept.hierarchyRoles.map { hr in
                                HierarchyRoleItem(
                                    id: hr.id,
                                    role: hr.hierarchyRole.rawValue,
                                    volunteerName: "\(hr.eventVolunteer.firstName) \(hr.eventVolunteer.lastName)",
                                    eventVolunteerId: hr.eventVolunteer.id,
                                    assignedAt: hr.assignedAt
                                )
                            },
                            volunteerCount: dept.volunteerCount
                        )
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Failed to load department"
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func setPrivacy(isPublic: Bool) {
        guard let dept = departmentInfo else { return }
        isSavingPrivacy = true

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.SetDepartmentPrivacyMutation(
                departmentId: dept.id,
                isPublic: isPublic
            )
        ) { [weak self] result in
            Task { @MainActor in
                self?.isSavingPrivacy = false
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data?.setDepartmentPrivacy {
                        self?.departmentInfo?.isPublic = data.isPublic
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Failed to update privacy"
                        HapticManager.shared.error()
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    HapticManager.shared.error()
                }
            }
        }
    }

    func assignAssistantOverseer(eventVolunteerId: String) {
        guard let dept = departmentInfo else { return }
        isAssigningRole = true
        errorMessage = nil

        let input = AssemblyOpsAPI.AssignHierarchyRoleInput(
            departmentId: dept.id,
            eventVolunteerId: eventVolunteerId,
            hierarchyRole: .case(.assistantOverseer)
        )

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.AssignHierarchyRoleMutation(input: input)
        ) { [weak self] result in
            Task { @MainActor in
                self?.isAssigningRole = false
                switch result {
                case .success(let graphQLResult):
                    if let role = graphQLResult.data?.assignHierarchyRole {
                        let item = HierarchyRoleItem(
                            id: role.id,
                            role: role.hierarchyRole.rawValue,
                            volunteerName: "\(role.eventVolunteer.firstName) \(role.eventVolunteer.lastName)",
                            eventVolunteerId: role.eventVolunteer.id,
                            assignedAt: role.assignedAt
                        )
                        self?.departmentInfo?.hierarchyRoles.append(item)
                        self?.successMessage = "deptSettings.role.assigned".localized
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Failed to assign role"
                        HapticManager.shared.error()
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    HapticManager.shared.error()
                }
            }
        }
    }

    func removeAssistantOverseer(eventVolunteerId: String) {
        guard let dept = departmentInfo else { return }

        NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.RemoveHierarchyRoleMutation(
                departmentId: dept.id,
                eventVolunteerId: eventVolunteerId
            )
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let graphQLResult):
                    if graphQLResult.data?.removeHierarchyRole == true {
                        self?.departmentInfo?.hierarchyRoles.removeAll { $0.eventVolunteerId == eventVolunteerId }
                        self?.successMessage = "deptSettings.role.removed".localized
                        HapticManager.shared.success()
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        self?.errorMessage = errors.first?.message ?? "Failed to remove role"
                        HapticManager.shared.error()
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    HapticManager.shared.error()
                }
            }
        }
    }
}
