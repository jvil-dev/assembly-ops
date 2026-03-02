//
//  AudioDashboardViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Audio Dashboard ViewModel
//
// Loads aggregate data for the Audio overseer dashboard.
// Fetches equipment summary, unresolved damage count, hazard assessments,
// and safety briefings in parallel.
//
// Used by: AudioDashboardView

import Foundation
import Combine

@MainActor
final class AudioDashboardViewModel: ObservableObject {
    @Published var equipmentSummary: AudioEquipmentSummaryItem?
    @Published var unresolvedDamageCount = 0
    @Published var hazardAssessments: [AudioHazardAssessmentItem] = []
    @Published var safetyBriefings: [AudioSafetyBriefingItem] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadDashboard(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            async let fetchSummary = AudioVideoService.shared.fetchEquipmentSummary(eventId: eventId)
            async let fetchDamage = AudioVideoService.shared.fetchDamageReports(eventId: eventId, resolved: false)
            async let fetchHazards = AudioVideoService.shared.fetchHazardAssessments(eventId: eventId)
            async let fetchBriefings = AudioVideoService.shared.fetchSafetyBriefings(eventId: eventId)

            let (summary, damage, hazards, briefings) = try await (fetchSummary, fetchDamage, fetchHazards, fetchBriefings)
            equipmentSummary = summary
            unresolvedDamageCount = damage.count
            hazardAssessments = hazards
            safetyBriefings = briefings
        } catch {
            self.error = error.localizedDescription
        }
    }
}
