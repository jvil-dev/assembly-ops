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
//   - Badge refresh tied to app scene phase (active/background)
//
// Dependencies:
//   - AppState: Injected via EnvironmentObject
//   - UnreadBadgeManager: Manages message badge count
//   - HomeView, AssignmentsListView, MessagesView, ProfileView

import SwiftUI

struct VolunteerTabView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var badgeManager = UnreadBadgeManager.shared
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
                
                MessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "envelope")
                    }
                    .badge(badgeManager.unreadCount)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
            }
            .onChange(of: scenePhase) {
                _, newPhase in
                switch newPhase {
                case .active:
                    badgeManager.startRefreshing()
                case .inactive, .background:
                    badgeManager.stopRefreshing()
                @unknown default:
                    break
                }
            }
            .onAppear {
                if scenePhase == .active {
                    badgeManager.startRefreshing()
                }
            }
        }
    }
}

#Preview {
    VolunteerTabView()
}
