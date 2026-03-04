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
    var eventId: String? = nil
    @StateObject private var viewModel = AssignmentsViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var showTodayOnly = false
    @State private var hasAppeared = false

    var body: some View {
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
        .themedBackground(scheme: colorScheme)
        .navigationTitle("tab.schedule".localized)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterButton
            }
        }
        .task {
            if !viewModel.hasLoaded {
                viewModel.fetchAssignments(eventId: eventId)
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
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
                DateUtils.isSessionDateToday(group.date)
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
                    // Pending Captain Roles section
                    if !viewModel.pendingCaptainAssignments.isEmpty {
                        Section {
                            ForEach(Array(viewModel.pendingCaptainAssignments.enumerated()), id: \.element.id) { index, captainAssignment in
                                NavigationLink {
                                    CaptainAssignmentDetailView(assignment: captainAssignment) {
                                        viewModel.refresh()
                                    }
                                } label: {
                                    CaptainAssignmentCardView(assignment: captainAssignment)
                                }
                                .buttonStyle(.plain)
                                .entranceAnimation(hasAppeared: hasAppeared, delay: Double(index) * 0.03)
                            }
                        } header: {
                            captainSectionHeader
                        }
                    }

                    if showTodayOnly && filteredGroupedAssignments.isEmpty {
                        noTodayAssignmentsView
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)
                    } else {
                        ForEach(Array(filteredGroupedAssignments.enumerated()), id: \.element.date) { groupIndex, group in
                            Section {
                                ForEach(Array(group.assignments.enumerated()), id: \.element.id) { index, assignment in
                                    NavigationLink {
                                        AssignmentDetailView(assignment: assignment)
                                            .onDisappear {
                                                viewModel.refresh()
                                            }
                                    } label: {
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

    // MARK: - Captain Section Header

    private var captainSectionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.StatusColors.warning)
            Text("captain.assignment.pending".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.s)
        .padding(.horizontal, AppTheme.Spacing.xs)
        .background(.ultraThinMaterial)
    }

    // MARK: - Date Headers

    private func dateHeader(for date: Date) -> some View {
        HStack {
            if DateUtils.isSessionDateToday(date) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.StatusColors.pending)
                        .frame(width: 8, height: 8)
                    Text("Today")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                }
                Text("• \(DateUtils.formatSessionDateAbbreviated(date))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else if DateUtils.isSessionDateTomorrow(date) {
                Text("Tomorrow")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
                Text("• \(DateUtils.formatSessionDateAbbreviated(date))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                Text(DateUtils.formatSessionDateFull(date))
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
