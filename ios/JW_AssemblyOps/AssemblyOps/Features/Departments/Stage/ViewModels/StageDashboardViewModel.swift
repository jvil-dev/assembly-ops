//
//  StageDashboardViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Stage Dashboard ViewModel
//
// Manages data for the Stage overseer dashboard.
// Loads department volunteers and walk-through completion records.
// No equipment, damage, or hazard data — Stage crew doesn't manage AV equipment.

import Foundation
import Combine

@MainActor
final class StageDashboardViewModel: ObservableObject {
    @Published var walkThroughCount = 0
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Load

    func loadDashboard(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let completions = try await AttendantService.shared.fetchMyWalkThroughCompletions()
            walkThroughCount = completions.count
        } catch {
            self.error = error.localizedDescription
        }
    }
}
