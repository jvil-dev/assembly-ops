//
//  OverseerTabView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/24/26.
//

// MARK: - Overseer Tab View
//
// Main tab navigation container for overseer users.
// Provides access to dashboard, volunteers, assignments, and profile screens.
//
// Tabs:
//   - Home: OverseerDashboardView with event overview and quick actions
//   - Volunteers: VolunteerListView for managing department volunteers
//   - Assignments: AssignmentsView with coverage matrix for scheduling
//   - Profile: OverseerProfileView for account settings and logout
//
// Features:
//   - Displays OfflineBanner at top when network connectivity is lost
//   - Animates banner visibility based on NetworkMonitor state
//   - iOS 26 glass tab bar styling with theme color tint
//

import SwiftUI

struct OverseerTabView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var sessionState = OverseerSessionState.shared

    private var tabTintColor: Color {
        if let dept = sessionState.selectedDepartment {
            return DepartmentColor.color(for: dept.departmentType)
        }
        return AppTheme.themeColor
    }

    var body: some View {
        VStack(spacing: 0) {
            OfflineBanner()
                .animation(.easeInOut, value: NetworkMonitor.shared.isConnected)

            TabView {
                OverseerDashboardView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                VolunteerListView()
                    .tabItem {
                        Label("Volunteers", systemImage: "person.3")
                    }

                AssignmentsView()
                    .tabItem {
                        Label("Assignments", systemImage: "tablecells")
                    }

                OverseerMessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "envelope")
                    }

                OverseerProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
            }
            .tint(tabTintColor)
        }
    }
}

#Preview {
    OverseerTabView()
        .environmentObject(AppState.shared)
}
