//
//  LostPersonViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Lost Person View Model
//
// Manages state for lost person alert list and resolution.
// Used by LostPersonAlertsView and ResolveLostPersonSheet.
//
// Published Properties:
//   - alerts: Filtered alert list
//   - showResolved: Toggle to include resolved alerts
//   - isLoading / error: Loading/error states
//
// Methods:
//   - loadAlerts(eventId:): Fetch alerts with resolved filter
//   - resolveAlert(id:notes:eventId:): Mark alert as resolved
//

import Foundation
import Apollo
import Combine

@MainActor
final class LostPersonViewModel: ObservableObject {
    @Published var alerts: [LostPersonAlertItem] = []
    @Published var showResolved = false
    @Published var isLoading = false
    @Published var error: String?

    var unresolvedCount: Int { alerts.filter { !$0.resolved }.count }

    func loadAlerts(eventId: String, resolved: Bool? = nil) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let filter: Bool? = resolved ?? (showResolved ? nil : false)
            alerts = try await AttendantService.shared.fetchLostPersonAlerts(eventId: eventId, resolved: filter)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func resolveAlert(id: String, resolutionNotes: String) async {
        do {
            try await AttendantService.shared.resolveLostPersonAlert(id: id, resolutionNotes: resolutionNotes)
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}
