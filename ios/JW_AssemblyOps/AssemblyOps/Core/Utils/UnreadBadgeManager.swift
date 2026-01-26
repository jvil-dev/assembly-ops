//
//  UnreadBadgeManager.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/13/26.
//

// MARK: - Unread Badge Manager
//
// Singleton that manages unread message count for tab badge.
// Polls server every 30 seconds when active.
//
// Published Properties:
//   - unreadCount: Current unread message count
//
// Methods:
//   - startRefreshing(): Begin periodic polling (call on appear)
//   - stopRefreshing(): Stop polling (call on disappear)
//   - fetchUnreadCount(): One-time fetch of unread count
//   - decrementCount(): Manually decrement when message read
//   - clearCount(): Reset to zero when all marked read
//
// Dependencies:
//   - MessagesService: API calls
//
// Used by: MainTabView

import Foundation
import Combine
import SwiftUI

/// Manages unread message count for tab badge
@MainActor
final class UnreadBadgeManager: ObservableObject {
    static let shared = UnreadBadgeManager()
    
    @Published var unreadCount: Int = 0
    
    private var refreshTask: Task<Void, Never>?
    
    private init() {}
    
    /// Start periodic refresh of unread count
    func startRefreshing() {
        stopRefreshing()
        
        refreshTask = Task {
            while !Task.isCancelled {
                await fetchUnreadCount()
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            }
        }
    }
    
    /// Stop periodic refresh
    func stopRefreshing() {
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
