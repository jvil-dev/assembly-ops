//
//  HomeViewModel.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/21/26.
//

// MARK: - Home View Model
//
// Drives the volunteer "At a Glance" dashboard with assignment data,
// today's summary, and relative-time countdown for the next assignment.
//
// Published Properties:
//   - assignments: All fetched Assignment objects
//   - isLoading: True while API request is in flight
//   - errorMessage: Error text to display (nil on success)
//   - now: Auto-updating Date for relative time calculations
//
// Computed Properties:
//   - todayAssignments: Accepted assignments for today, sorted by startTime
//   - currentActiveAssignment: First checked-in assignment (NOW state)
//   - nextUpAssignment: Next accepted assignment not yet completed
//   - todayTotal/todayCompleted/todayCheckedIn/todayUpcoming: Summary stats
//   - hasTodayAssignments, allDoneForToday, hasFutureAssignments, nextAssignmentDate
//
// Methods:
//   - loadAssignments(): Offline-first fetch with cache fallback
//   - refresh(): Pull-to-refresh alias
//   - checkIn/checkOut: Perform action then reload
//
// Dependencies:
//   - AssignmentsService, CheckInService, AssignmentCache, NetworkMonitor

import Foundation
import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var assignments: [Assignment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var now = Date()

    private var timerCancellable: AnyCancellable?
    private let cache = AssignmentCache.shared
    private let networkMonitor = NetworkMonitor.shared

    init() {
        // Update `now` every 60 seconds so relative time text stays fresh
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.now = date
            }
    }

    // MARK: - Computed Properties

    /// Today's accepted assignments sorted by start time
    var todayAssignments: [Assignment] {
        assignments
            .filter { $0.isToday && $0.isAccepted }
            .sorted { $0.startTime < $1.startTime }
    }

    /// Currently active assignment (volunteer is checked in right now)
    var currentActiveAssignment: Assignment? {
        todayAssignments.first { $0.isCheckedIn }
    }

    /// Next upcoming accepted assignment that hasn't been completed
    /// Priority: today's not-yet-done assignments, then future assignments
    var nextUpAssignment: Assignment? {
        // First try today: accepted, not checked out, not checked in
        let todayNext = todayAssignments
            .filter { !$0.isCheckedOut && !$0.isCheckedIn }
            .first

        if let todayNext { return todayNext }

        // Then try future accepted assignments
        return assignments
            .filter { !$0.isToday && $0.isAccepted && $0.date >= Calendar.current.startOfDay(for: now) }
            .sorted { $0.date < $1.date || ($0.date == $1.date && $0.startTime < $1.startTime) }
            .first
    }

    var hasTodayAssignments: Bool {
        !todayAssignments.isEmpty
    }

    var todayTotal: Int {
        todayAssignments.count
    }

    var todayCompleted: Int {
        todayAssignments.filter { $0.isCheckedOut }.count
    }

    var todayCheckedIn: Int {
        todayAssignments.filter { $0.isCheckedIn }.count
    }

    var todayUpcoming: Int {
        todayAssignments.filter { !$0.isCheckedIn && !$0.isCheckedOut }.count
    }

    var allDoneForToday: Bool {
        hasTodayAssignments && todayAssignments.allSatisfy { $0.isCheckedOut }
    }

    var hasFutureAssignments: Bool {
        assignments.contains { !$0.isToday && $0.date > now && $0.isAccepted }
    }

    var nextAssignmentDate: Date? {
        assignments
            .filter { !$0.isToday && $0.date > now && $0.isAccepted }
            .sorted { $0.date < $1.date }
            .first?.date
    }

    var hasAnyAssignments: Bool {
        assignments.contains { $0.isAccepted }
    }

    // MARK: - Relative Time

    func relativeTimeText(for assignment: Assignment) -> String {
        let interval = assignment.startTime.timeIntervalSince(now)

        if interval <= 0 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "in \(minutes) min"
        } else if interval < 7200 {
            let hours = Int(interval / 3600)
            let remaining = Int((interval - Double(hours * 3600)) / 60)
            if remaining > 0 {
                return "in \(hours)h \(remaining)m"
            }
            return "in \(hours) hour"
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "starts at \(formatter.string(from: assignment.startTime))"
        }
    }

    // MARK: - Data Loading

    func loadAssignments(eventId: String? = nil) async {
        isLoading = true
        errorMessage = nil

        // Offline: try cache first
        if !networkMonitor.isConnected {
            if let cached = cache.load() {
                assignments = cached
                isLoading = false
                return
            }
        }

        // Network fetch
        guard let resolvedEventId = eventId ?? AppState.shared.currentEventId else {
            isLoading = false
            return
        }
        let eventId = resolvedEventId
        do {
            let fetched = try await AssignmentsService.shared.fetchAssignments(eventId: eventId)
            assignments = fetched
            cache.save(fetched)
            if !fetched.isEmpty {
                AppState.shared.hasVolunteerEventMembership = true
            }
        } catch {
            // Fallback to cache on failure
            if let cached = cache.load() {
                assignments = cached
            } else {
                errorMessage = "Unable to load assignments. Check your connection"
            }
        }

        isLoading = false
    }

    func refresh(eventId: String? = nil) async {
        await loadAssignments(eventId: eventId)
    }

    // MARK: - Check-In Actions

    func checkIn(assignmentId: String) async {
        do {
            _ = try await CheckInService.shared.checkIn(assignmentId: assignmentId)
            HapticManager.shared.success()
            await loadAssignments()
        } catch {
            HapticManager.shared.error()
            errorMessage = error.localizedDescription
        }
    }

    func checkOut(assignmentId: String) async {
        do {
            _ = try await CheckInService.shared.checkOut(assignmentId: assignmentId)
            HapticManager.shared.success()
            await loadAssignments()
        } catch {
            HapticManager.shared.error()
            errorMessage = error.localizedDescription
        }
    }
}
