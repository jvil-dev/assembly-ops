//
//  CheckInStatsViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/9/26.
//

// MARK: - Check-In Stats View Model
//
// Manages state and business logic for volunteer check-in statistics.
// Provides session-by-session breakdown of volunteer participation.
//
// Types:
//   - CheckInStatsItem: Session stats with assigned/checked-in counts
//
// Published Properties:
//   - stats: List of check-in stats by session
//   - isLoading: Loading state indicator
//   - errorMessage: Error display message
//
// Methods:
//   - loadStats(eventId:departmentId:): Fetch check-in statistics for event/department

import Foundation
import Apollo
import Combine

struct CheckInStatsItem: Identifiable {
    var id: String { sessionId }
    let sessionId: String
    let sessionName: String
    let totalAssignments: Int
    let checkedIn: Int
    let checkedOut: Int
    let noShow: Int
    let pending: Int
    
    var checkedInRate: Double {
        guard totalAssignments > 0 else { return 0 }
        return Double(checkedIn) / Double(totalAssignments)
    }
    
    var attendanceRate: Double {
        guard totalAssignments > 0 else { return 0 }
        return Double(checkedIn + checkedOut) / Double(totalAssignments)
    }
}

@MainActor
final class CheckInStatsViewModel: ObservableObject {
    @Published var stats: [CheckInStatsItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadStats(sessionIds: [String], sessionNames: [String: String]) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        var results: [CheckInStatsItem] = []
        for sessionId in sessionIds {
            do {
                let result = try await NetworkClient.shared.apollo.fetch(
                    query: AssemblyOpsAPI.CheckInStatsQuery(sessionId: sessionId),
                    cachePolicy: .fetchIgnoringCacheData
                )

                if let data = result.data?.checkInStats {
                    let sessionName = sessionNames[sessionId] ?? "Unknown Session"
                    let item = CheckInStatsItem(
                        sessionId: data.sessionId,
                        sessionName: sessionName,
                        totalAssignments: data.totalAssignments,
                        checkedIn: data.checkedIn,
                        checkedOut: data.checkedOut,
                        noShow: data.noShow,
                        pending: data.pending
                    )
                    results.append(item)
                }
            } catch {
                // Skip failed sessions, continue loading others
                print("Failed to load stats for session \(sessionId): \(error)")
            }
        }
        stats = results
    }

    func loadStatsForLatestSession(sessions: [SessionAttendanceSummaryItem]) async {
        guard let latest = sessions.first else { return }
        let sessionNames = [latest.sessionId: latest.sessionName]
        await loadStats(sessionIds: [latest.sessionId], sessionNames: sessionNames)
    }
}
