//
//  VideoVolunteerViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Volunteer ViewModel
//
// Volunteer-facing ViewModel for the Video department.
// Loads safety briefings, active checkouts, and video equipment list.
//
// Used by: VideoVolunteerDeptView, VideoWalkThroughChecklistView, ReportVideoDamageView

import Foundation
import Combine

@MainActor
final class VideoVolunteerViewModel: ObservableObject {
    @Published var myBriefings: [AudioSafetyBriefingItem] = []
    @Published var activeCheckouts: [AudioEquipmentCheckoutItem] = []
    @Published var equipment: [AudioEquipmentItemModel] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var hasMediaAssignment = false
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
            let (briefings, checkouts, allEquipment) = try await (fetchBriefings, fetchCheckouts, fetchEquipment)
            myBriefings = briefings
            activeCheckouts = checkouts
            // Filter to video-relevant categories only
            equipment = allEquipment.filter { AudioEquipmentCategoryItem.videoRelevantCategories.contains($0.category) }

            // Check if volunteer has a Media post assignment
            let cached = AssignmentCache.shared.load() ?? []
            hasMediaAssignment = cached.contains {
                $0.postName.localizedCaseInsensitiveContains("Media") && $0.departmentType == "VIDEO"
            }
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
