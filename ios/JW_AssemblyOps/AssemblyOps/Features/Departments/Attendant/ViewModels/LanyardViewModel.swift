//
//  LanyardViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Lanyard ViewModel
//
// Manages lanyard pickup/return tracking for attendant volunteers.
// Handles both volunteer self-service and overseer operations.
//
// Properties:
//   - myStatus: Current volunteer's lanyard status
//   - allStatuses: All volunteers' statuses (overseer view)
//   - summary: Aggregate counts
//   - isLoading, error: Standard loading state
//
// Methods:
//   - loadMyStatus(eventId:): Fetch volunteer's own status
//   - pickUp(eventId:): Mark lanyard picked up
//   - returnLanyard(eventId:): Mark lanyard returned
//   - loadAllStatuses(eventId:): Fetch all statuses (overseer)
//   - overseerPickUp(eventVolunteerId:): Overseer marks pickup
//   - overseerReturn(eventVolunteerId:): Overseer marks return
//

import Foundation
import Combine

struct LanyardStatusItem: Identifiable {
    let id: String
    let eventVolunteerId: String
    let date: String
    let pickedUpAt: String?
    let returnedAt: String?
    let volunteerName: String

    var status: LanyardState {
        if returnedAt != nil { return .returned }
        if pickedUpAt != nil { return .pickedUp }
        return .notPickedUp
    }
}

enum LanyardState {
    case notPickedUp
    case pickedUp
    case returned
}

struct LanyardSummaryItem {
    let total: Int
    let pickedUp: Int
    let returned: Int
    let notPickedUp: Int
}

@MainActor
class LanyardViewModel: ObservableObject {
    @Published var myStatus: LanyardStatusItem?
    @Published var allStatuses: [LanyardStatusItem] = []
    @Published var summary: LanyardSummaryItem?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Volunteer Operations

    func loadMyStatus(eventId: String) async {
        isLoading = true
        error = nil

        do {
            myStatus = try await AttendantService.shared.fetchMyLanyardStatus(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func pickUp(eventId: String) async {
        error = nil

        do {
            myStatus = try await AttendantService.shared.pickUpLanyard(eventId: eventId)
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func returnLanyard(eventId: String) async {
        error = nil

        do {
            myStatus = try await AttendantService.shared.returnLanyard(eventId: eventId)
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Overseer Operations

    func loadAllStatuses(eventId: String) async {
        isLoading = true
        error = nil

        do {
            allStatuses = try await AttendantService.shared.fetchLanyardStatuses(eventId: eventId)
            summary = try await AttendantService.shared.fetchLanyardSummary(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func overseerPickUp(eventVolunteerId: String, eventId: String) async {
        error = nil

        do {
            try await AttendantService.shared.overseerPickUpLanyard(eventVolunteerId: eventVolunteerId)
            await loadAllStatuses(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func overseerReturn(eventVolunteerId: String, eventId: String) async {
        error = nil

        do {
            try await AttendantService.shared.overseerReturnLanyard(eventVolunteerId: eventVolunteerId)
            await loadAllStatuses(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
