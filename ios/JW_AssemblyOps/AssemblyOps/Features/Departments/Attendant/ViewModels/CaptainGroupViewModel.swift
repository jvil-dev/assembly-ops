//
//  CaptainGroupViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Captain Group View Model
//
// Manages data and actions for the captain group roster.
// Fetches group members and handles captain check-in operations.
//
// Published Properties:
//   - members: Array of GroupMember objects in the captain's group
//   - isLoading: True while fetching data
//   - showError: Triggers error alert
//   - errorMessage: Error text to display
//
// Methods:
//   - loadGroup(postId:sessionId:): Fetch group members from API
//   - checkInMember(assignmentId:): Check in a group member via captain check-in
//
// Dependencies:
//   - AssignmentsService: API calls (getCaptainGroup, captainCheckIn)
//   - HapticManager: Success/error feedback
//
// Used by: CaptainGroupView

import Foundation
import Combine

@MainActor
class CaptainGroupViewModel: ObservableObject {
    @Published var members: [GroupMember] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let assignmentsService = AssignmentsService.shared

    func loadGroup(postId: String, sessionId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            members = try await assignmentsService.getCaptainGroup(postId: postId, sessionId: sessionId)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func checkInMember(assignmentId: String) async {
        do {
            try await assignmentsService.captainCheckIn(assignmentId: assignmentId, notes: nil)
            HapticManager.shared.success()

            // Update local state
            if let index = members.firstIndex(where: { $0.assignmentId == assignmentId }) {
                let member = members[index]
                members[index] = GroupMember(
                    id: member.id,
                    firstName: member.firstName,
                    lastName: member.lastName,
                    congregation: member.congregation,
                    phone: member.phone,
                    assignmentId: member.assignmentId,
                    assignmentStatus: member.assignmentStatus,
                    isCheckedIn: true,
                    checkInTime: Date()
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.error()
        }
    }
}
