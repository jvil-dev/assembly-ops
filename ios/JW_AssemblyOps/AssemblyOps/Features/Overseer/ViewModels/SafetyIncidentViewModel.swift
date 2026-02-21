//
//  SafetyIncidentViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Safety Incident View Model
//
// Manages state for safety incident list and resolution.
// Used by SafetyIncidentListView and ResolveIncidentSheet.
//
// Published Properties:
//   - incidents: Filtered incident list
//   - showResolved: Toggle to include resolved incidents
//   - isLoading / error: Loading/error states
//
// Methods:
//   - loadIncidents(eventId:): Fetch incidents with resolved filter
//   - resolveIncident(id:notes:eventId:): Mark incident as resolved
//

import Foundation
import Apollo
import Combine

@MainActor
final class SafetyIncidentViewModel: ObservableObject {
    @Published var incidents: [SafetyIncidentItem] = []
    @Published var showResolved = false
    @Published var isLoading = false
    @Published var error: String?

    var unresolvedCount: Int { incidents.filter { !$0.resolved }.count }

    func loadIncidents(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let resolved: Bool? = showResolved ? nil : false
            incidents = try await AttendantService.shared.fetchSafetyIncidents(eventId: eventId, resolved: resolved)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func resolveIncident(id: String, notes: String?, eventId: String) async {
        do {
            try await AttendantService.shared.resolveSafetyIncident(id: id, resolutionNotes: notes)
            HapticManager.shared.success()
            await loadIncidents(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}
