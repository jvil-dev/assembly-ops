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
    private var currentEventId: String?

    private init() {}

    /// Start periodic refresh of pending count
    func startRefreshing(eventId: String? = nil) {
        if let eventId { currentEventId = eventId }
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

    /// Fetch pending count once (post assignments + captain assignments)
    func fetchPendingCount(eventId: String? = nil) async {
        guard let resolvedEventId = eventId ?? currentEventId ?? AppState.shared.currentEventId else { return }
        do {
            async let postAssignments = AssignmentsService.shared.fetchAssignments(eventId: resolvedEventId)
            async let captainAssignments = AssignmentsService.shared.fetchCaptainAssignments(eventId: resolvedEventId)

            let (posts, captains) = try await (postAssignments, captainAssignments)
            pendingCount = posts.filter { $0.status == .pending }.count +
                           captains.filter { $0.status == .pending }.count
        } catch {
            #if DEBUG
            print("Failed to fetch pending count: \(error)")
            #endif
        }
    }

    /// Manual refresh trigger
    func refresh(eventId: String? = nil) async {
        await fetchPendingCount(eventId: eventId)
    }
}
