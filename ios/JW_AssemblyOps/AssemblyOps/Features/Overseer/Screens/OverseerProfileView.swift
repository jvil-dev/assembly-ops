//
//  OverseerProfileView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Overseer Profile View
//
// Profile and settings screen for overseer users.
// Displays account info, current event context, and logout option.
//
// Sections:
//   - Account: Name, email, role (Event/Department Overseer)
//   - Current Event: Active event name and venue
//   - Department: Current department (if selected)
//   - Logout: Destructive button with confirmation dialog
//
// Features:
//   - Reads overseer info from AppState.currentOverseer
//   - Reads event/department context from OverseerSessionState
//   - Logout clears tokens and returns to landing screen
//

import SwiftUI

struct OverseerProfileView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let overseer = appState.currentOverseer {
                        LabeledContent("Name", value: overseer.fullName)
                        LabeledContent("Email", value: overseer.email)
                        LabeledContent("Role", value: formatRole(overseer.overseerType))
                    }
                }

                if let event = sessionState.selectedEvent {
                    Section("Current Event") {
                        LabeledContent("Event", value: event.name)
                        LabeledContent("Venue", value: event.venue)
                    }
                }

                if let department = sessionState.selectedDepartment {
                    Section("Department") {
                        LabeledContent("Department", value: department.name)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog(
                "Are you sure you want to log out?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Log Out", role: .destructive) {
                    appState.logout()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func formatRole(_ overseerType: String) -> String {
        switch overseerType {
        case "EVENT_OVERSEER":
            return "Event Overseer"
        case "DEPARTMENT_OVERSEER":
            return "Department Overseer"
        default:
            return overseerType
        }
    }
}
