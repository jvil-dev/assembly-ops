//
//  AttendanceViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/8/26.
//

// MARK: - Attendance View Model
//
// Manages state and business logic for attendance tracking screens.
// Handles both session-level count submissions and event-wide summaries.
//
// Published Properties:
//   - sessionSummaries: Event-wide attendance data by session
//   - currentSessionCounts: Detailed counts for selected session
//   - sessions: Available sessions for picker
//   - isLoading: Loading state indicator
//   - errorMessage: Error display message
//
// Methods:
//   - loadSessions(eventId:): Fetch all event sessions
//   - loadEventSummary(eventId:): Fetch attendance summary across sessions
//   - loadSessionCounts(sessionId:): Fetch detailed counts for specific session
//   - submitCount(sessionId:count:section:notes:): Submit new attendance count
//   - updateCount(countId:count:section:notes:): Update existing count
//   - deleteCount(countId:): Delete attendance count

import Foundation
import Apollo
import Combine

@MainActor
final class AttendanceViewModel: ObservableObject {
    @Published var sessionSummaries: [SessionAttendanceSummaryItem] = []
    @Published var currentSessionCounts: [AttendanceCountItem] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var successMessage: String?

    // Input form state
    @Published var selectedSessionId: String?
    @Published var sectionName: String = ""
    @Published var countText: String = ""
    @Published var notes: String = ""

    var eventTotal: Int {
        sessionSummaries.reduce(0) { $0 + $1.totalCount }
    }

    // MARK: - Queries

    func loadEventSummary(eventId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            sessionSummaries = try await AttendanceService.shared.fetchEventAttendanceSummary(eventId: eventId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadSessionCounts(sessionId: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            currentSessionCounts = try await AttendanceService.shared.fetchSessionAttendanceCounts(sessionId: sessionId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Mutations

    func submitCount() async {
        guard let sessionId = selectedSessionId,
              let count = Int(countText), count >= 0 else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let section = sectionName.isEmpty ? nil : sectionName
            let noteText = notes.isEmpty ? nil : notes
            _ = try await AttendanceService.shared.submitAttendanceCount(
                sessionId: sessionId, section: section, count: count, notes: noteText
            )
            HapticManager.shared.success()
            successMessage = "Count submitted"
            // Reset form
            countText = ""
            sectionName = ""
            notes = ""
            // Reload
            await loadSessionCounts(sessionId: sessionId)
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }
    }

    func deleteCount(id: String, sessionId: String) async {
        do {
            _ = try await AttendanceService.shared.deleteAttendanceCount(id: id)
            HapticManager.shared.success()
            await loadSessionCounts(sessionId: sessionId)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
