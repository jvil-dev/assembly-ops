//
//  HomeView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Home View
//
// Dashboard screen showing event overview and quick access to key info.
// First tab in the main navigation.
//
// Components:
//   - Event header: Current event name
//   - Today card: Current date display
//   - (Placeholder for upcoming assignments and stats)
//
// Dependencies:
//   - AppState: Access to current volunteer and event info
//
// Used by: MainTabView.swift (Home tab)

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Event details
                    eventDetailsSection
                        .padding(.horizontal)

                    // Pending assignments
                    pendingAssignmentsSection
                        .padding(.horizontal)

                    // Latest message
                    latestMessageSection
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Home")
        }
    }

    // MARK: - Event Details

    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Details")
                .font(.headline)
                .foregroundStyle(Color("ThemeColor"))

            VStack(alignment: .leading, spacing: 8) {
                // Theme (placeholder until we wire up the data)
                if let theme = appState.currentVolunteer?.eventTheme {
                    Text(theme)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                // Venue
                if let venue = appState.currentVolunteer?.eventVenue {
                    Text(venue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Department
                if let department = appState.currentVolunteer?.departmentName {
                    Text(department)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Pending Assignments

    private var pendingAssignmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Assignments")
                .font(.headline)
                .foregroundStyle(Color("ThemeColor"))

            // Empty state for now
            Text("No pending assignments")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Latest Message

    private var latestMessageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Latest Message")
                    .font(.headline)
                    .foregroundStyle(Color("ThemeColor"))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Empty state for now
            Text("No unread messages")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState.shared)
}
