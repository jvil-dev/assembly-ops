//
//  AssignmentsViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Assignments View Model
//
// Fetches and manages the volunteer's schedule assignments.
// Implements offline-first pattern with local caching.
//
// Published Properties:
//   - assignments: Array of all fetched Assignment objects
//   - isLoading: True while API request is in flight
//   - errorMessage: Error text to display (nil on success)
//   - hasLoaded: True after first fetch (prevents reload on tab switch)
//   - isUsingCache: True when displaying cached data instead of live
//
// Computed Properties:
//   - groupedAssignments: Assignments grouped by date, sorted chronologically
//   - todayAssignments: Only assignments scheduled for today
//   - upcomingAssignments: Today and future assignments
//   - isEmpty: True if no assignments exist
//   - pendingCount: Count of pending assignments requiring response
//   - hasPendingAssignments: True if any pending assignments exist
//   - pendingAssignments: Pending assignments sorted by date
//   - acceptedAssignments: Accepted assignments sorted by date
//
// Methods:
//   - fetchAssignments(): Fetch from API with cache fallback
//   - refresh(): Alias for fetchAssignments (pull-to-refresh)
//
// Offline Behavior:
//   - If offline: Load from cache immediately
//   - If online: Fetch from API, cache result
//   - On network failure: Fall back to cache with indicator
//
// Dependencies:
//   - AssignmentsService: GraphQL API calls
//   - AssignmentCache: Local persistence
//   - NetworkMonitor: Connectivity status
//
// Used by: AssignmentsListView


import Foundation
import SwiftUI
import Combine
import Apollo

@MainActor
final class AssignmentsViewModel: ObservableObject {
    @Published var assignments: [Assignment] = []
    @Published var captainAssignments: [CaptainAssignment] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasLoaded: Bool = false
    @Published var isUsingCache = false
    
    private let cache = AssignmentCache.shared
    private let networkMonitor = NetworkMonitor.shared
    
    /// Assignments grouped by date, sorted chronologically.
    /// Attendant assignments with a shift use the shift start time for ordering;
    /// all other assignments use the session start time.
    var groupedAssignments: [(date: Date, assignments: [Assignment])] {
        let grouped = Dictionary(grouping: assignments) { assignment in
            DateUtils.sessionStartOfDay(for: assignment.date)
        }
        return grouped
            .map { (date: $0.key, assignments: $0.value.sorted { $0.displayStartTime < $1.displayStartTime }) }
            .sorted { $0.date < $1.date }
    }
    
    /// Today's assignments
    var todayAssignments: [Assignment] {
        assignments.filter { $0.isToday }
    }
    
    /// Upcoming assignments (today and future)
    var upcomingAssignments: [Assignment] {
        assignments.filter { $0.isUpcoming }
    }
    
    /// Check if there are any assignments (post or captain)
    var isEmpty: Bool {
        assignments.isEmpty && captainAssignments.isEmpty
    }

    /// Count of pending assignments requiring response (post + captain)
    var pendingCount: Int {
        assignments.filter { $0.status == .pending }.count +
        captainAssignments.filter { $0.status == .pending }.count
    }

    /// True if there are any pending assignments
    var hasPendingAssignments: Bool {
        pendingCount > 0
    }

    /// Pending post assignments sorted by date
    var pendingAssignments: [Assignment] {
        assignments.filter { $0.status == .pending }
            .sorted { $0.date < $1.date }
    }

    /// Pending captain assignments sorted by date
    var pendingCaptainAssignments: [CaptainAssignment] {
        captainAssignments.filter { $0.status == .pending }
            .sorted { $0.date < $1.date }
    }

    /// Accepted captain assignments
    var acceptedCaptainAssignments: [CaptainAssignment] {
        captainAssignments.filter { $0.status == .accepted }
            .sorted { $0.date < $1.date }
    }

    /// Accepted post assignments sorted by date
    var acceptedAssignments: [Assignment] {
        assignments.filter { $0.status == .accepted }
            .sorted { $0.date < $1.date }
    }

    /// Fetch assignments from API
    func fetchAssignments(eventId: String? = nil) {
        guard let resolvedEventId = eventId ?? AppState.shared.currentEventId else { return }
        let eventId = resolvedEventId
        isLoading = true
        errorMessage = nil

        // If offline, try cache first
        if !networkMonitor.isConnected {
            if let cached = cache.load() {
                assignments = cached
                isUsingCache = true
                isLoading = false
                hasLoaded = true
                return
            }
        }

        // Try network fetch
        Task {
            defer {
                isLoading = false
                hasLoaded = true
            }
            do {
                async let fetchedAssignments = AssignmentsService.shared.fetchAssignments(eventId: eventId)
                async let fetchedCaptain = AssignmentsService.shared.fetchCaptainAssignments(eventId: eventId)

                let (postAssignments, captainResults) = try await (fetchedAssignments, fetchedCaptain)
                assignments = postAssignments
                captainAssignments = captainResults
                isUsingCache = false

                // Cache for offline use
                cache.save(postAssignments)
            } catch {
                if let cached = cache.load() {
                    assignments = cached
                    isUsingCache = true
                    errorMessage = NSLocalizedString("showing_cached_data", comment: "")
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func refresh() {
        fetchAssignments()
    }
}
