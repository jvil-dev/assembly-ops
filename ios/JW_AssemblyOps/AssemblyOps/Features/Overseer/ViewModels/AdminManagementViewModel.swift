//
//  AdminManagementViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/1/26.
//

// MARK: - Admin Management ViewModel
//
// State management for the Admin Management screen.
// Fetches event administrators and handles promotion to App Admin.
//
// Properties:
//   - eventAdmins: List of all administrators for the current event
//   - isLoading: True while fetching admin list
//   - isPromoting: True while a promotion mutation is in-flight
//   - error: Error message from the last failed operation
//
// Methods:
//   - loadEventAdmins(eventId:): Fetch all admins via EventAdminsQuery
//   - promoteToAppAdmin(eventId:adminId:): Promote a Department Overseer
//
// Authorization:
//   - Promotion is only visible to App Admins (enforced by the view)
//   - Backend enforces APP_ADMIN-only access on the mutation
//

import Foundation
import Combine
import Apollo

@MainActor
final class AdminManagementViewModel: ObservableObject {
    @Published var eventAdmins: [EventAdminItem] = []
    @Published var isLoading = false
    @Published var isPromoting = false
    @Published var error: String?

    func loadEventAdmins(eventId: String) async {
        isLoading = true
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.EventAdminsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            )

            guard let admins = result.data?.eventAdmins else {
                error = "Failed to load administrators"
                isLoading = false
                return
            }

            eventAdmins = admins.map { admin in
                EventAdminItem(
                    id: admin.id,
                    adminId: admin.user.id,
                    fullName: "\(admin.user.firstName) \(admin.user.lastName)",
                    email: admin.user.email,
                    role: admin.role.rawValue,
                    departmentName: admin.department?.name,
                    claimedAt: DateUtils.isoFormatter.date(from: admin.claimedAt) ?? Date()
                )
            }
        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func promoteToAppAdmin(eventId: String, adminId: String) async throws {
        isPromoting = true
        defer { isPromoting = false }

        let input = AssemblyOpsAPI.PromoteToAppAdminInput(
            eventId: eventId,
            adminId: adminId
        )

        _ = try await NetworkClient.shared.apollo.perform(
            mutation: AssemblyOpsAPI.PromoteToAppAdminMutation(input: input)
        )

        HapticManager.shared.success()
        await loadEventAdmins(eventId: eventId)
    }
}

struct EventAdminItem: Identifiable {
    let id: String
    let adminId: String
    let fullName: String
    let email: String
    let role: String
    let departmentName: String?
    let claimedAt: Date

    var isAppAdmin: Bool { role == "APP_ADMIN" }
}
