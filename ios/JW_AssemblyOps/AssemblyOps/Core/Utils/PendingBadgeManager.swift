//
//  PendingBadgeManager.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/26/26.
//

// MARK: - Pending Badge Manager
//
// Singleton that manages pending assignment count for tab badge.
// Polls server every 60 seconds when active.
//
// Published Properties:
//   - pendingCount: Current pending assignment count
//
// Methods:
//   - startRefreshing(): Begin periodic polling (call on appear)
//   - stopRefreshing(): Stop polling (call on disappear)
//   - fetchPendingCount(): One-time fetch of pending count
//   - refresh(): Manual refresh trigger
//
// Dependencies:
//   - AssignmentsService: API calls
//
// Used by: EventTabView (Assignments tab badge)

import Foundation
import Combine

/// Manages pending assignment count for tab badge
@MainActor
final class PendingBadgeManager: ObservableObject {
    static let shared = PendingBadgeManager()

    @Published var pendingCount: Int = 0

    private var refreshTask: Task<Void, Never>?

    private init() {}

    /// Start periodic refresh of pending count
    func startRefreshing() {
        stopRefreshing()

        refreshTask = Task {
            while !Task.isCancelled {
                await fetchPendingCount()
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
            }
        }
    }

    /// Stop periodic refresh
    func stopRefreshing() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Fetch pending count once
    func fetchPendingCount() async {
        do {
            let assignments = try await AssignmentsService.shared.fetchAssignments()
            pendingCount = assignments.filter { $0.status == .pending }.count
        } catch {
            print("Failed to fetch pending count: \(error)")
        }
    }

    /// Manual refresh trigger
    func refresh() async {
        await fetchPendingCount()
    }
}
