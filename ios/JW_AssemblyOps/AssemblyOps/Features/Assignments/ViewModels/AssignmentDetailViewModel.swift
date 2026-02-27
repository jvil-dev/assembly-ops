//
//  AssignmentDetailViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Assignment Detail View Model
//
// Manages actions for the assignment detail screen.
// Handles accept/decline and check-in/out operations.
//
// Published Properties:
//   - isLoading: True during async operations
//   - showError: Triggers error alert
//   - errorMessage: Error text to display
//
// Methods:
//   - acceptAssignment(): Accept a pending assignment
//   - declineAssignment(reason:): Decline with optional reason
//   - checkIn(): Check in to the assignment
//   - checkOut(): Check out from the assignment
//
// Dependencies:
//   - AssignmentsService: Accept/decline API calls
//   - CheckInService: Check-in/out API calls
//   - HapticManager: Success/error feedback
//
// Used by: AssignmentDetailView

import Foundation
import SwiftUI
import Combine

@MainActor
class AssignmentDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let assignment: Assignment
    private let assignmentsService = AssignmentsService.shared

    init(assignment: Assignment) {
        self.assignment = assignment
    }

    func acceptAssignment() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await assignmentsService.acceptAssignment(assignmentId: assignment.id)
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.error()
        }
    }

    func declineAssignment(reason: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await assignmentsService.declineAssignment(assignmentId: assignment.id, reason: reason)
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.error()
        }
    }

    func checkIn() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await CheckInService.shared.checkIn(assignmentId: assignment.id)
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.error()
        }
    }

    func checkOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await CheckInService.shared.checkOut(assignmentId: assignment.id)
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.shared.error()
        }
    }
}
