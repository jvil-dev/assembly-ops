//
//  UnreadBadgeManager.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Unread Badge Manager
//
// Singleton that manages unread message count for tab badge.
// Uses WebSocket subscription for real-time updates with polling fallback.
//
// Published Properties:
//   - unreadCount: Current unread message count
//
// Methods:
//   - startRefreshing(): Begin subscription + fallback polling (call on appear)
//   - stopRefreshing(): Stop subscription + polling (call on disappear)
//   - fetchUnreadCount(): One-time fetch of unread count
//   - decrementCount(): Manually decrement when message read
//   - clearCount(): Reset to zero when all marked read
//
// Dependencies:
//   - MessagesService: API calls + subscription
//
// Used by: EventTabView

import Foundation
import Combine
import SwiftUI
import Apollo

/// Manages unread message count for tab badge
@MainActor
final class UnreadBadgeManager: ObservableObject {
    static let shared = UnreadBadgeManager()

    @Published var unreadCount: Int = 0

    private var refreshTask: Task<Void, Never>?
    private var subscription: Apollo.Cancellable?

    private init() {}

    /// Start subscription + fallback polling
    func startRefreshing() {
        stopRefreshing()

        // Real-time subscription for instant badge updates
        subscription = MessagesService.shared.subscribeToUnreadCount { [weak self] count in
            Task { @MainActor in
                #if DEBUG
                print("[UnreadBadge] Badge updated via subscription: \(count)")
                #endif
                self?.unreadCount = count
            }
        }

        // Fallback polling at 60s in case subscription drops
        refreshTask = Task {
            await fetchUnreadCount()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                await fetchUnreadCount()
            }
        }
    }

    /// Stop subscription + polling
    func stopRefreshing() {
        subscription?.cancel()
        subscription = nil
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Fetch unread count once
    func fetchUnreadCount() async {
        do {
            unreadCount = try await MessagesService.shared.fetchUnreadCount()
        } catch {
            print("Failed to fetch unread count: \(error)")
        }
    }

    /// Decrement count (when message read)
    func decrementCount() {
        unreadCount = max(0, unreadCount - 1)
    }

    /// Clear count (when all marked read)
    func clearCount() {
        unreadCount = 0
    }
}
