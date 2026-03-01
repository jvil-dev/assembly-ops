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

    func loadIncidents(eventId: String, resolved: Bool? = nil) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let filter: Bool? = resolved ?? (showResolved ? nil : false)
            incidents = try await AttendantService.shared.fetchSafetyIncidents(eventId: eventId, resolved: filter)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func resolveIncident(id: String, resolutionNotes: String?) async {
        do {
            try await AttendantService.shared.resolveSafetyIncident(id: id, resolutionNotes: resolutionNotes)
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}
