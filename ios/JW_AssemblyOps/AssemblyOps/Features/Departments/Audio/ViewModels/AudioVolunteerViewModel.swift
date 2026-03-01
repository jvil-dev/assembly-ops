//
//  AudioVolunteerViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Audio Volunteer ViewModel
//
// Volunteer-facing ViewModel for Audio departments.
// Loads the volunteer's safety briefings and active checkouts.
// Supports reporting damage from the volunteer side.
//
// Used by: AudioVolunteerDeptView, AudioWalkThroughChecklistView, ReportDamageView

import Foundation
import Combine

@MainActor
final class AudioVolunteerViewModel: ObservableObject {
    @Published var myBriefings: [AudioSafetyBriefingItem] = []
    @Published var activeCheckouts: [AudioEquipmentCheckoutItem] = []
    @Published var equipment: [AudioEquipmentItemModel] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?

    // MARK: - Load

    func loadVolunteerData(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            async let fetchBriefings = AudioVideoService.shared.fetchMySafetyBriefings(eventId: eventId)
            async let fetchCheckouts = AudioVideoService.shared.fetchCheckouts(eventId: eventId, checkedIn: false)
            async let fetchEquipment = AudioVideoService.shared.fetchEquipment(eventId: eventId)
            (myBriefings, activeCheckouts, equipment) = try await (fetchBriefings, fetchCheckouts, fetchEquipment)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Report Damage

    func reportDamage(equipmentId: String, description: String, severity: String,
                      sessionId: String? = nil) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            _ = try await AudioVideoService.shared.reportDamage(
                equipmentId: equipmentId, description: description,
                severity: severity, sessionId: sessionId
            )
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }
}
