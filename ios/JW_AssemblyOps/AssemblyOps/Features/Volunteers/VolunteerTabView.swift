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
//   - Programmatic tab selection for cross-tab navigation from HomeView
//
// Dependencies:
//   - AppState: Injected via EnvironmentObject
//   - UnreadBadgeManager: Manages message badge count
//   - PendingBadgeManager: Manages pending assignment badge count
//   - HomeView, AssignmentsListView, MessagesView, ProfileView

import SwiftUI

/// Tab identifiers for programmatic tab switching
enum VolunteerTab: Int {
    case home, schedule, messages, profile
}

struct VolunteerTabView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var messageBadgeManager = UnreadBadgeManager.shared
    @ObservedObject private var pendingBadgeManager = PendingBadgeManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: VolunteerTab = .home

    private var tabTintColor: Color {
        if let deptType = appState.currentVolunteer?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    var body: some View {
        VStack(spacing: 0) {
            OfflineBanner()
                .animation(.easeInOut, value: NetworkMonitor.shared.isConnected)

            TabView(selection: $selectedTab) {
                HomeView(switchToTab: { selectedTab = $0 })
                    .tabItem {
                        Label("tab.home".localized, systemImage: "house")
                    }
                    .tag(VolunteerTab.home)

                AssignmentsListView()
                    .tabItem {
                        Label("tab.schedule".localized, systemImage: "calendar")
                    }
                    .badge(pendingBadgeManager.pendingCount)
                    .tag(VolunteerTab.schedule)

                MessagesView()
                    .tabItem {
                        Label("tab.messages".localized, systemImage: "envelope")
                    }
                    .badge(messageBadgeManager.unreadCount)
                    .tag(VolunteerTab.messages)

                ProfileView()
                    .tabItem {
                        Label("tab.profile".localized, systemImage: "person")
                    }
                    .tag(VolunteerTab.profile)
            }
            .tint(tabTintColor)
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
