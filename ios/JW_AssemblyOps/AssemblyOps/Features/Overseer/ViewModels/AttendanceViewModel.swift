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
    @Published var count: Int = 0
    @Published var notes: String = ""

    // Section picker state (populated from Attendant department posts)
    @Published var attendantPosts: [AttendantPostItem] = []
    @Published var selectedPost: AttendantPostItem?
    @Published var useCustomSection: Bool = false

    var eventTotal: Int {
        sessionSummaries.reduce(0) { $0 + $1.totalCount }
    }

    /// Returns the section name to submit based on picker or custom input
    var effectiveSectionName: String? {
        if useCustomSection {
            return sectionName.isEmpty ? nil : sectionName
        }
        return selectedPost?.name
    }

    // MARK: - Queries

    /// Load Attendant department posts for the section picker (overseer path)
    func loadAttendantPosts(departments: [DepartmentSummary]) async {
        guard let attendantDept = departments.first(where: { $0.departmentType == "ATTENDANT" }) else {
            return
        }
        await loadAttendantPosts(departmentId: attendantDept.id)
    }

    /// Load Attendant department posts by departmentId directly (volunteer path)
    func loadAttendantPosts(departmentId: String) async {
        do {
            attendantPosts = try await AttendanceService.shared.fetchAttendantPosts(departmentId: departmentId)
        } catch {
            // Non-fatal: fall back to free-text if posts fail to load
            print("[AttendanceVM] Failed to load attendant posts: \(error)")
        }
    }

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
        guard let sessionId = selectedSessionId, count >= 0 else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let section = effectiveSectionName
            let noteText = notes.isEmpty ? nil : notes
            _ = try await AttendanceService.shared.submitAttendanceCount(
                sessionId: sessionId, section: section, postId: selectedPost?.id, count: count, notes: noteText
            )
            HapticManager.shared.success()
            successMessage = "attendance.submitted".localized
            // Reset form
            count = 0
            sectionName = ""
            selectedPost = nil
            useCustomSection = false
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
