//
//  AssignmentsViewModel.swift
//  JW_AssemblyOps
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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasLoaded: Bool = false
    @Published var isUsingCache = false
    
    private let cache = AssignmentCache.shared
    private let networkMonitor = NetworkMonitor.shared
    
    /// Assignments grouped by date
    var groupedAssignments: [(date: Date, assignments: [Assignment])] {
        let grouped = Dictionary(grouping: assignments) { assignment in
            Calendar.current.startOfDay(for: assignment.date)
        }
        return grouped
            .map { (date: $0.key, assignments: $0.value.sorted { $0.startTime < $1.startTime }) }
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
    
    /// Check if there are any assignments
    var isEmpty: Bool {
        assignments.isEmpty
    }
    
    /// Fetch assignments from API
    func fetchAssignments() {
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
            do {
                let fetched = try await AssignmentsService.shared.fetchAssignments()
                assignments = fetched
                isUsingCache = false
                
                // Cache for offline use
                cache.save(fetched)
            } catch {
                // On network failure, fall back to cache
                if let cached = cache.load() {
                    assignments = cached
                    isUsingCache = true
                    errorMessage = "Showing cached data. Pull to refresh"
                } else {
                    errorMessage = "Unable to load assignments. Check your connection"
                }
                isLoading = false
                hasLoaded = true
            }
        } 
        isLoading = false
        hasLoaded = true
      }

      func refresh() {
          fetchAssignments()
      }
}
