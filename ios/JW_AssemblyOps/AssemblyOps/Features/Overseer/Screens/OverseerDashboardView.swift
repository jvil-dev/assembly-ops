//
//  OverseerDashboardView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 1/25/26.
//

// MARK: - Overseer Dashboard View
//
// Main home screen for overseer users showing event overview and quick stats.
// Uses the app's design system with warm backgrounds and floating cards.
//
// Sections:
//   - Event Picker Header: Tap to switch events (shows current event name/venue)
//   - Dashboard Content: Event statistics, quick actions, coverage summary
//
// Features:
//   - Auto-loads events on appear via OverseerSessionState.loadEvents()
//   - Displays selectEventPrompt when no event selected
//   - Warm gradient background with floating cards
//   - Staggered entrance animations
//   - Department Settings navigation card
//
// Navigation:
//   - EventPickerSheet: Modal for event selection
//   - DepartmentSettingsView: Department configuration and hierarchy
//

import SwiftUI

struct OverseerDashboardView: View {
    @StateObject private var sessionState = OverseerSessionState.shared
    @StateObject private var attendanceVM = AttendanceViewModel()
    @StateObject private var checkInStatsVM = CheckInStatsViewModel()
    @StateObject private var messagesVM = SentMessagesViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var showEventPicker = false
    @State private var hasAppeared = false

    private var departmentAccentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Event picker header
                eventPickerHeader
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                if let event = sessionState.selectedEvent {
                    if sessionState.selectedDepartment?.departmentType == "ATTENDANT" {
                        AttendantDashboardView()
                    } else {
                        dashboardContent(for: event)
                    }
                } else {
                    selectEventPrompt
                }
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("overseer.dashboard.title".localized)
            .sheet(isPresented: $showEventPicker) {
                EventPickerSheet()
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
        .task {
            await sessionState.loadEvents()

            // Load attendance summary - provides session data for check-in stats
            if let eventId = sessionState.selectedEvent?.id {
                await attendanceVM.loadEventSummary(eventId: eventId)
                await checkInStatsVM.loadStatsForLatestSession(sessions: attendanceVM.sessionSummaries)
                await messagesVM.fetchMessages()
            }
        }
    }

    // MARK: - Event Picker Header

    private var eventPickerHeader: some View {
        Button {
            showEventPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(sessionState.selectedEvent?.name ?? "overseer.dashboard.selectEvent".localized)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    if let venue = sessionState.selectedEvent?.venue {
                        Text(venue)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .cardPadding()
            .background(AppTheme.cardBackground(for: colorScheme))
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private func dashboardContent(for event: EventSummary) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Quick stats cards
                statsSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                // Department Settings
                if let dept = sessionState.claimedDepartment {
                    departmentSettingsCard(department: dept)
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.13)
                }

                // Join requests
                joinRequestsCard(eventId: event.id)
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                // Assignments overview
                assignmentsOverviewSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.18)

                // Check-in stats and attendance actions
                recentActivitySection
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    // MARK: - Department Settings Card

    private func departmentSettingsCard(department: DepartmentSummary) -> some View {
        NavigationLink(destination: DepartmentSettingsView(departmentId: department.id)) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(departmentAccentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "gearshape.2")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(departmentAccentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("departmentSettings.title".localized)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    Text(department.name)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Join Requests Card

    private func joinRequestsCard(eventId: String) -> some View {
        NavigationLink(destination: JoinRequestsView(eventId: eventId)) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(AppTheme.StatusColors.pendingBackground)
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.StatusColors.pending)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("overseer.joinRequests.title".localized)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    Text("overseer.joinRequests.subtitle".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var selectEventPrompt: some View {
        ContentUnavailableView(
            "overseer.dashboard.noEvent.title".localized,
            systemImage: "calendar",
            description: Text("overseer.dashboard.noEvent.subtitle".localized)
        )
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        LazyVGrid(columns: [.init(), .init()], spacing: AppTheme.Spacing.m) {
            StatCard(
                title: "overseer.dashboard.stat.volunteers".localized,
                value: "\(sessionState.selectedDepartment?.volunteerCount ?? sessionState.selectedEvent?.volunteerCount ?? 0)",
                icon: "person.3",
                accentColor: departmentAccentColor,
                colorScheme: colorScheme
            )
            StatCard(
                title: "overseer.dashboard.stat.assignments".localized,
                value: "—",
                icon: "calendar",
                accentColor: departmentAccentColor,
                colorScheme: colorScheme
            )
            StatCard(
                title: "overseer.dashboard.stat.pending".localized,
                value: "—",
                icon: "clock",
                accentColor: departmentAccentColor,
                colorScheme: colorScheme
            )
            StatCard(
                title: "overseer.dashboard.stat.coverage".localized,
                value: "—",
                icon: "chart.pie",
                accentColor: departmentAccentColor,
                colorScheme: colorScheme
            )
        }
    }

    // MARK: - Assignments Overview

    private var assignmentsOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            Text("overseer.dashboard.assignmentsOverview".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(departmentAccentColor)

            HStack {
                Spacer()
                VStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("overseer.dashboard.assignmentsHint".localized)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.l)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Check-In Stats

    @ViewBuilder
    private var recentActivitySection: some View {
        // Check-In Stats (if available)
        if let currentStats = checkInStatsVM.stats.first {
            NavigationLink(destination: CheckInStatsView()) {
                CheckInStatsCard(stats: currentStats)
            }
            .buttonStyle(.plain)
        }

        // Attendance Quick Actions
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "number")
                    .foregroundStyle(departmentAccentColor)
                Text("overseer.dashboard.attendance".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            NavigationLink(destination: AttendanceInputView()) {
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(departmentAccentColor)
                        .frame(width: 24)

                    Text("overseer.dashboard.submitCount".localized)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            }
            .buttonStyle(.plain)

            NavigationLink(destination: AttendanceSummaryView()) {
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundStyle(departmentAccentColor)
                        .frame(width: 24)

                    Text("overseer.dashboard.viewSummary".localized)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            }
            .buttonStyle(.plain)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)

    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var accentColor: Color = AppTheme.themeColor
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(accentColor)

            Text(value)
                .font(AppTheme.Typography.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }
}

#Preview {
    OverseerDashboardView()
}

#Preview("Dark Mode") {
    OverseerDashboardView()
        .preferredColorScheme(.dark)
}
