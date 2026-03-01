//
//  AudioSafetyViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Audio Safety ViewModel
//
// Manages hazard assessments and safety briefings CRUD.
// Loads both data sets for the safety management screen.
//
// Used by: AudioHazardAssessmentView, CreateHazardAssessmentSheet,
//          AudioSafetyBriefingsView, CreateSafetyBriefingSheet

import Foundation
import Combine

@MainActor
final class AudioSafetyViewModel: ObservableObject {
    @Published var hazardAssessments: [AudioHazardAssessmentItem] = []
    @Published var safetyBriefings: [AudioSafetyBriefingItem] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?

    // MARK: - Load

    func loadHazards(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            hazardAssessments = try await AudioVideoService.shared.fetchHazardAssessments(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadBriefings(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            safetyBriefings = try await AudioVideoService.shared.fetchSafetyBriefings(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadAll(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            async let fetchHazards = AudioVideoService.shared.fetchHazardAssessments(eventId: eventId)
            async let fetchBriefings = AudioVideoService.shared.fetchSafetyBriefings(eventId: eventId)
            (hazardAssessments, safetyBriefings) = try await (fetchHazards, fetchBriefings)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Hazard Assessments

    func createHazardAssessment(eventId: String, title: String, hazardType: String,
                                description: String, controls: String,
                                ppeRequired: [String], sessionId: String? = nil) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let item = try await AudioVideoService.shared.createHazardAssessment(
                eventId: eventId, title: title, hazardType: hazardType,
                description: description, controls: controls,
                ppeRequired: ppeRequired, sessionId: sessionId
            )
            hazardAssessments.insert(item, at: 0)
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }

    func deleteHazardAssessment(id: String) async -> Bool {
        do {
            try await AudioVideoService.shared.deleteHazardAssessment(id: id)
            hazardAssessments.removeAll { $0.id == id }
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }

    // MARK: - Safety Briefings

    func createSafetyBriefing(eventId: String, topic: String, notes: String? = nil,
                              attendeeIds: [String]) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let item = try await AudioVideoService.shared.createSafetyBriefing(
                eventId: eventId, topic: topic, notes: notes, attendeeIds: attendeeIds
            )
            safetyBriefings.insert(item, at: 0)
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }

    func updateBriefingNotes(id: String, notes: String) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            try await AudioVideoService.shared.updateSafetyBriefingNotes(id: id, notes: notes)
            if let index = safetyBriefings.firstIndex(where: { $0.id == id }) {
                safetyBriefings[index] = AudioSafetyBriefingItem(
                    id: safetyBriefings[index].id,
                    topic: safetyBriefings[index].topic,
                    notes: notes,
                    conductedByName: safetyBriefings[index].conductedByName,
                    conductedAt: safetyBriefings[index].conductedAt,
                    attendeeCount: safetyBriefings[index].attendeeCount,
                    attendees: safetyBriefings[index].attendees
                )
            }
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }

    func deleteSafetyBriefing(id: String) async -> Bool {
        do {
            try await AudioVideoService.shared.deleteSafetyBriefing(id: id)
            safetyBriefings.removeAll { $0.id == id }
            HapticManager.shared.success()
            return true
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
            return false
        }
    }
}
