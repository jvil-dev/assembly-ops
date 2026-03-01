//
//  VideoDamageViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Damage ViewModel
//
// Manages damage report list, creation, and resolution for the Video crew.
// Delegates to AudioVideoService (shared backend).
//
// Used by: VideoDamageReportsView, ResolveVideoDamageSheet, ReportVideoDamageView

import Foundation
import Combine

@MainActor
final class VideoDamageViewModel: ObservableObject {
    @Published var reports: [AudioDamageReportItem] = []
    @Published var showResolved = false
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?

    var filteredReports: [AudioDamageReportItem] {
        showResolved ? reports : reports.filter { !$0.resolved }
    }

    var unresolvedCount: Int {
        reports.filter { !$0.resolved }.count
    }

    // MARK: - Load

    func loadReports(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            reports = try await AudioVideoService.shared.fetchDamageReports(eventId: eventId, resolved: nil)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Report

    func reportDamage(equipmentId: String, description: String, severity: String,
                      sessionId: String? = nil) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let report = try await AudioVideoService.shared.reportDamage(
                equipmentId: equipmentId, description: description,
                severity: severity, sessionId: sessionId
            )
            reports.insert(report, at: 0)
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }

    // MARK: - Resolve

    func resolveDamage(id: String, resolutionNotes: String? = nil, eventId: String) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            try await AudioVideoService.shared.resolveDamage(id: id, resolutionNotes: resolutionNotes)
            HapticManager.shared.success()
            await loadReports(eventId: eventId)
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }
}
