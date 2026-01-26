//
//  OverseerDashboardView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Overseer Dashboard View
//
// Main home screen for overseer users showing event overview and quick stats.
// Provides access to event/department selection and key metrics.
//
// Sections:
//   - Event Picker Header: Tap to switch events (shows current event name/venue)
//   - Department Selector: Event Overseers can switch departments (hidden for Dept Overseers)
//   - Dashboard Content: Event statistics, quick actions, coverage summary
//
// Features:
//   - Auto-loads events on appear via OverseerSessionState.loadEvents()
//   - Conditionally shows department picker for Event Overseers
//   - Displays selectEventPrompt when no event selected
//
// Navigation:
//   - EventPickerSheet: Modal for event selection
//   - DepartmentPickerSheet: Modal for department selection (Event Overseers)
//

import SwiftUI

struct OverseerDashboardView: View {
    @StateObject private var sessionState = OverseerSessionState.shared
    @State private var showEventPicker = false
    @State private var showDepartmentPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Event picker header
                eventPickerHeader

                // Department selector (Event Overseers only)
                if sessionState.isEventOverseer && sessionState.selectedEvent != nil {
                    departmentSelector
                }

                if let event = sessionState.selectedEvent {
                    dashboardContent(for: event)
                } else {
                    selectEventPrompt
                }
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showEventPicker) {
                EventPickerSheet()
            }
            .sheet(isPresented: $showDepartmentPicker) {
                DepartmentPickerSheet()
            }
        }
        .task {
            await sessionState.loadEvents()
        }
    }

    private var eventPickerHeader: some View {
        Button {
            showEventPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionState.selectedEvent?.name ?? "Select Event")
                        .font(.headline)
                    if let venue = sessionState.selectedEvent?.venue {
                        Text(venue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.down")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
        }
        .buttonStyle(.plain)
    }

    /// Department selector for Event Overseers to switch between departments
    private var departmentSelector: some View {
        Button {
            showDepartmentPicker = true
        } label: {
            HStack {
                Image(systemName: "building.2")
                    .foregroundStyle(Color("ThemeColor"))
                Text(sessionState.selectedDepartment?.name ?? "All Departments")
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemBackground))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dashboardContent(for event: EventSummary) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick stats cards
                statsSection

                // Assignments overview (formerly coverage)
                assignmentsOverviewSection

                // Recent activity
                recentActivitySection
            }
            .padding()
        }
    }

    private var selectEventPrompt: some View {
        ContentUnavailableView(
            "No Event Selected",
            systemImage: "calendar",
            description: Text("Tap above to select an event to manage")
        )
    }

    private var statsSection: some View {
        LazyVGrid(columns: [.init(), .init()], spacing: 12) {
            StatCard(title: "Volunteers", value: "\(sessionState.selectedDepartment?.volunteerCount ?? 0)", icon: "person.3")
            StatCard(title: "Assignments", value: "—", icon: "calendar")
            StatCard(title: "Pending", value: "—", icon: "clock")
            StatCard(title: "Coverage", value: "—", icon: "chart.pie")
        }
    }

    private var assignmentsOverviewSection: some View {
        // Simplified assignments preview
        Text("Assignments Overview")
    }

    private var recentActivitySection: some View {
        // Recent check-ins, accepts, declines
        Text("Recent Activity")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color("ThemeColor"))
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OverseerDashboardView()
}
