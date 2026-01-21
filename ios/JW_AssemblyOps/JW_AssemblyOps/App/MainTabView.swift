//
//  MainTabView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Main Tab View
//
// Root navigation container for authenticated users.
// Provides tab-based navigation between main app sections.
//
// Tabs:
//   - Home: Dashboard with event info and quick stats
//   - Schedule: List of volunteer assignments
//   - Messages: Overseer messages (placeholder)
//   - Profile: Volunteer info and logout
//
// Dependencies:
//   - AppState: Injected via EnvironmentObject
//   - HomeView, AssignmentsListView, MessagesView, ProfileView
//
// Used by: JW_AssemblyOpsApp.swift (when logged in)

import SwiftUI

struct MainTabView: View {
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
    MainTabView()
}
