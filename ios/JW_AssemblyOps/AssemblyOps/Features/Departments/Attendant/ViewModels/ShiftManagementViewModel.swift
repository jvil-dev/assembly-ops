//
//  ShiftManagementViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 3/1/26.
//

// MARK: - Shift Management View Model
//
// Manages shift CRUD for the overseer shift management UI.
//
// Properties:
//   - shifts: All shifts for the selected session
//   - sessions: Available sessions for the event
//   - isLoading: Loading state
//   - error: Error message
//
// Methods:
//   - loadSessions(eventId:): Fetch available sessions
//   - loadShifts(sessionId:): Fetch shifts for a session
//   - createShift(sessionId:postId:startTime:endTime:): Create a new shift
//   - updateShift(id:startTime:endTime:): Update a shift
//   - deleteShift(id:): Delete a shift
//

import Foundation
import Combine
import Apollo

@MainActor
final class ShiftManagementViewModel: ObservableObject {
    @Published var shifts: [ShiftItem] = []
    @Published var sessions: [EventSessionItem] = []
    @Published var selectedSession: EventSessionItem?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Load Sessions

    func loadSessions(eventId: String) async {
        isLoading = true
        error = nil

        do {
            let result = try await NetworkClient.shared.apollo.fetch(
                query: AssemblyOpsAPI.EventSessionsQuery(eventId: eventId),
                cachePolicy: .fetchIgnoringCacheData
            )

            guard let data = result.data?.sessions else {
                error = "Failed to load sessions"
                isLoading = false
                return
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let fallback = ISO8601DateFormatter()

            sessions = data.map { session in
                EventSessionItem(
                    id: session.id,
                    name: session.name,
                    date: formatter.date(from: session.date) ?? fallback.date(from: session.date) ?? Date(),
                    startTime: formatter.date(from: session.startTime) ?? fallback.date(from: session.startTime) ?? Date(),
                    assignmentCount: session.assignmentCount
                )
            }

            // Auto-select first session if none selected
            if selectedSession == nil, let first = sessions.first {
                selectedSession = first
                await loadShifts(sessionId: first.id)
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Load Shifts

    func loadShifts(sessionId: String) async {
        error = nil

        do {
            shifts = try await AttendantService.shared.fetchShifts(sessionId: sessionId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Create Shift

    func createShift(sessionId: String, postId: String, startTime: String, endTime: String) async {
        isLoading = true
        error = nil

        do {
            let newShift = try await AttendantService.shared.createShift(
                sessionId: sessionId,
                postId: postId,
                startTime: startTime,
                endTime: endTime
            )
            shifts.append(newShift)
            shifts.sort { $0.startTime < $1.startTime }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Update Shift

    func updateShift(id: String, startTime: String?, endTime: String?) async {
        error = nil

        do {
            let updated = try await AttendantService.shared.updateShift(
                id: id,
                startTime: startTime,
                endTime: endTime
            )
            if let index = shifts.firstIndex(where: { $0.id == id }) {
                shifts[index] = updated
                shifts.sort { $0.startTime < $1.startTime }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Delete Shift

    func deleteShift(id: String) async {
        error = nil

        do {
            try await AttendantService.shared.deleteShift(id: id)
            shifts.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Delete Assignment

    func deleteAssignment(id: String) async {
        error = nil

        do {
            let _ = try await NetworkClient.shared.apollo.perform(
                mutation: AssemblyOpsAPI.DeleteAssignmentMutation(id: id)
            )
            // Remove from local shift assignments
            for i in shifts.indices {
                shifts[i].assignments.removeAll { $0.id == id }
            }
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }
}
