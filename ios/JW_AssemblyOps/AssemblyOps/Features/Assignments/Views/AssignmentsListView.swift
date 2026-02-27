//
//  AssignmentsListView.swift
//  AssemblyOps
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
//   - Date headers show "Today" (with dot), "Tomorrow", or full date
//   - Today filter with haptic feedback on toggle
//
// Dependencies:
//   - AssignmentsViewModel: Fetches and manages assignment data
//   - AssignmentCardView: Individual assignment display
//   - Assignment: Data model (extended with Hashable for navigation)
//   - HapticManager: Haptic feedback on filter toggle
//
// Used by: EventTabView (Assignments tab, volunteer role)

import SwiftUI

struct AssignmentsListView: View {
    @StateObject private var viewModel = AssignmentsViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var showTodayOnly = false
    @State private var hasAppeared = false

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
                    ScrollView {
                        EmptyAssignmentsView()
                    }
                    .refreshable {
                        viewModel.refresh()
                    }
                } else {
                    assignmentsList
                }
            }
            .navigationTitle("schedule.title".localized)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            .task {
                if !viewModel.hasLoaded {
                    viewModel.fetchAssignments()
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Filter Button

    private var filterButton: some View {
        Button {
            showTodayOnly.toggle()
            HapticManager.shared.lightTap()
        } label: {
            Label(
                showTodayOnly ? "schedule.filter.all".localized : "schedule.filter.today".localized,
                systemImage: showTodayOnly ? "calendar" : "sun.max"
            )
        }
    }

    // MARK: - Filtered Data

    private var filteredGroupedAssignments: [(date: Date, assignments: [Assignment])] {
        if showTodayOnly {
            return viewModel.groupedAssignments.filter { group in
                Calendar.current.isDateInToday(group.date)
            }
        }
        return viewModel.groupedAssignments
    }

    // MARK: - Assignments List

    private var assignmentsList: some View {
        VStack(spacing: 0) {
            if viewModel.isUsingCache {
                cacheIndicator
            }

            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.l, pinnedViews: .sectionHeaders) {
                    if showTodayOnly && filteredGroupedAssignments.isEmpty {
                        noTodayAssignmentsView
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                    } else {
                        ForEach(Array(filteredGroupedAssignments.enumerated()), id: \.element.date) { groupIndex, group in
                            Section {
                                ForEach(Array(group.assignments.enumerated()), id: \.element.id) { index, assignment in
                                    NavigationLink(value: assignment) {
                                        AssignmentCardView(assignment: assignment)
                                    }
                                    .buttonStyle(.plain)
                                    .entranceAnimation(
                                        hasAppeared: hasAppeared,
                                        delay: Double(groupIndex) * 0.05 + Double(index) * 0.03
                                    )
                                }
                            } header: {
                                dateHeader(for: group.date)
                            }
                        }
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .refreshable {
                viewModel.refresh()
            }
            .themedBackground(scheme: colorScheme)
            .navigationDestination(for: Assignment.self) { assignment in
                AssignmentDetailView(assignment: assignment) {
                    viewModel.refresh()
                }
            }
        }
    }

    // MARK: - Cache Indicator

    private var cacheIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.arrow.circlePath")
            if let timestamp = AssignmentCache.shared.cacheTimestamp {
                Text("Last updated \(timestamp.formatted(date: .omitted, time: .shortened))")
            } else {
                Text("Showing cached data")
            }
        }
        .font(AppTheme.Typography.caption)
        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        .padding(.vertical, AppTheme.Spacing.s)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
    }

    // MARK: - No Today View

    private var noTodayAssignmentsView: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "sun.max")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("schedule.noToday.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("schedule.noToday.subtitle".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)

            Button("schedule.showAll".localized) {
                showTodayOnly = false
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.themeColor)
        }
        .padding(.top, 60)
    }

    // MARK: - Date Headers

    private func dateHeader(for date: Date) -> some View {
        HStack {
            if Calendar.current.isDateInToday(date) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.StatusColors.pending)
                        .frame(width: 8, height: 8)
                    Text("Today")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                }
                Text("• \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else if Calendar.current.isDateInTomorrow(date) {
                Text("Tomorrow")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
                Text("• \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.s)
        .padding(.horizontal, AppTheme.Spacing.xs)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    AssignmentsListView()
}
