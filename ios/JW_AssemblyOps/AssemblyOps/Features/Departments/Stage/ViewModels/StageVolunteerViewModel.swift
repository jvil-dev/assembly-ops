//
//  StageVolunteerViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Stage Volunteer ViewModel
//
// Manages data for the Stage volunteer view.
// Stage volunteers don't manage equipment — they use the pre-show
// participant reminder checklist (Appendix F) and see their role info.

import Foundation
import Combine

@MainActor
final class StageVolunteerViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Load
    // Stage volunteers have no async data to fetch beyond their assignment,
    // which is already available through AppState/EventSessionState.
    // This ViewModel is a placeholder for future role-specific data.

    func loadData(eventId: String) async {
        // No remote data needed for Stage volunteers at this time.
        // Role info comes from StageModels.swift (static content).
    }
}
