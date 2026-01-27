//
//  VolunteerTabView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Volunteer Tab View
//
// Root navigation container for volunteer users.
// Provides tab-based navigation between main volunteer sections.
//
// Tabs:
//   - Home: Dashboard with event info and quick stats
//   - Schedule: List of volunteer assignments
//   - Messages: Messages from overseers
//   - Profile: Volunteer info and logout
//
// Features:
//   - Displays OfflineBanner at top when network connectivity is lost
//   - Unread message badge on Messages tab
//   - Pending assignment badge on Schedule tab
//   - Badge refresh tied to app scene phase (active/background)
//   - iOS 26 glass tab bar styling with theme color tint
//
// Dependencies:
//   - AppState: Injected via EnvironmentObject
//   - UnreadBadgeManager: Manages message badge count
//   - PendingBadgeManager: Manages pending assignment badge count
//   - HomeView, AssignmentsListView, MessagesView, ProfileView

import SwiftUI

struct VolunteerTabView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var messageBadgeManager = UnreadBadgeManager.shared
    @ObservedObject private var pendingBadgeManager = PendingBadgeManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            OfflineBanner()
                .animation(.easeInOut, value: NetworkMonitor.shared.isConnected)

            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                AssignmentsListView()
                    .tabItem {
                        Label("Schedule", systemImage: "calendar")
                    }
                    .badge(pendingBadgeManager.pendingCount)

                MessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "envelope")
                    }
                    .badge(messageBadgeManager.unreadCount)

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
            }
            .tint(AppTheme.themeColor) // Theme color for tab bar and glass effect on iOS 26
            .onChange(of: scenePhase) {
                _, newPhase in
                switch newPhase {
                case .active:
                    messageBadgeManager.startRefreshing()
                    pendingBadgeManager.startRefreshing()
                case .inactive, .background:
                    messageBadgeManager.stopRefreshing()
                    pendingBadgeManager.stopRefreshing()
                @unknown default:
                    break
                }
            }
            .onAppear {
                if scenePhase == .active {
                    messageBadgeManager.startRefreshing()
                    pendingBadgeManager.startRefreshing()
                }
            }
        }
    }
}

#Preview {
    VolunteerTabView()
        .environmentObject(AppState.shared)
}
