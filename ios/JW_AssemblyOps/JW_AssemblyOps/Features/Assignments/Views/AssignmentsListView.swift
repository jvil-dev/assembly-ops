//
//  AssignmentsListView.swift
//  JW_AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Assignments List View
//
// Main schedule screen displaying all volunteer assignments grouped by date.
// Handles loading, error, and empty states with pull-to-refresh support.
//
// Components:
//   - Loading state: LoadingView while fetching
//   - Error state: ErrorView with retry button
//   - Empty state: EmptyAssignmentsView when no assignments
//   - List: Assignments grouped by date with sticky headers
//   - Filter button: Toggle between all assignments and today only
//   - No today view: Shown when filtering to today with no assignments
//
// Behavior:
//   - Fetches assignments on first appear (via .task)
//   - Pull-to-refresh triggers refetch
//   - Tapping a card navigates to AssignmentDetailView
//   - Date headers show "Today" (with orange dot), "Tomorrow", or full date
//   - Today filter with haptic feedback on toggle
//
// Dependencies:
//   - AssignmentsViewModel: Fetches and manages assignment data
//   - AssignmentCardView: Individual assignment display
//   - Assignment: Data model (extended with Hashable for navigation)
//   - HapticManager: Haptic feedback on filter toggle
//
// Used by: MainTabView.swift (Schedule tab)

import SwiftUI

struct AssignmentsListView: View {
    @StateObject private var viewModel = AssignmentsViewModel()
    @State private var showTodayOnly = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && !viewModel.hasLoaded {
                    LoadingView(message: "Loading schedule...")
                } else if let error = viewModel.errorMessage, viewModel.isEmpty {
                    ErrorView(message: error) {
                        viewModel.refresh()
                    }
                } else if viewModel.isEmpty {
                    EmptyAssignmentsView()
                } else {
                    assignmentsList
                }
            }
            .navigationTitle("My Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            .refreshable {
                viewModel.refresh()
            }
            .task {
                if !viewModel.hasLoaded {
                    viewModel.fetchAssignments()
                }
            }
        }
    }
    
    private var filterButton: some View {
        Button {
            showTodayOnly.toggle()
            HapticManager.shared.lightTap()
        } label: {
            Label(
                showTodayOnly ? "All" : "Today",
                systemImage: showTodayOnly ? "calendar" : "sun.max"
            )
        }
    }
    
    private var filteredGroupedAssignments: [(date: Date, assignments: [Assignment])] {
        if showTodayOnly {
            let today = viewModel.groupedAssignments.filter { group in
                Calendar.current.isDateInToday(group.date)
            }
            return today
        }
        return viewModel.groupedAssignments
    }
    
    private var assignmentsList: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                if showTodayOnly && filteredGroupedAssignments.isEmpty {
                    noTodayAssignmentsView
                } else {
                    ForEach(filteredGroupedAssignments, id: \.date) { group in
                        Section {
                            ForEach(group.assignments) { assignment in
                                NavigationLink(value: assignment) {
                                    AssignmentCardView(assignment: assignment)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            dateHeader(for: group.date)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(for: Assignment.self) { assignment in
            AssignmentDetailView(assignment: assignment)
        }
    }
    
    private var noTodayAssignmentsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sun.max")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("No Assignments Today")
                .font(.headline)
            
            Text("You don't have any assignments scheduled for today.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Show All Assignments") {
                showTodayOnly = false
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 60)
    }
    
    private func dateHeader(for date: Date) -> some View {
        HStack {
            if Calendar.current.isDateInToday(date) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Today")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Text("• \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if Calendar.current.isDateInTomorrow(date) {
                Text("Tomorrow")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("• \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(.headline)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    AssignmentsListView()
}
