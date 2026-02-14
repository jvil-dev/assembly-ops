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
//   - Department Selector: Event Overseers can switch departments (hidden for Dept Overseers)
//   - Dashboard Content: Event statistics, quick actions, coverage summary
//
// Features:
//   - Auto-loads events on appear via OverseerSessionState.loadEvents()
//   - Conditionally shows department picker for Event Overseers
//   - Displays selectEventPrompt when no event selected
//   - Warm gradient background with floating cards
//   - Staggered entrance animations
//
// Navigation:
//   - EventPickerSheet: Modal for event selection
//   - DepartmentPickerSheet: Modal for department selection (Event Overseers)
//

import SwiftUI

struct OverseerDashboardView: View {
    @StateObject private var sessionState = OverseerSessionState.shared
    @StateObject private var attendanceVM = AttendanceViewModel()
    @StateObject private var checkInStatsVM = CheckInStatsViewModel()
    @StateObject private var messagesVM = SentMessagesViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var showEventPicker = false
    @State private var showDepartmentPicker = false
    @State private var showCreateSession = false
    @State private var showCreatePost = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Event picker header
                eventPickerHeader
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // Department selector (Event Overseers only)
                if sessionState.isEventOverseer && sessionState.selectedEvent != nil {
                    departmentSelector
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                }

                if let event = sessionState.selectedEvent {
                    dashboardContent(for: event)
                } else {
                    selectEventPrompt
                }
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        // Session creation (APP_ADMIN only)
                        if sessionState.isEventOverseer {
                            Button {
                                showCreateSession = true
                            } label: {
                                Label("session.create".localized, systemImage: "calendar.badge.plus")
                            }
                        }

                        // Post creation (any admin with department)
                        if sessionState.selectedDepartment != nil {
                            Button {
                                showCreatePost = true
                            } label: {
                                Label("post.create".localized, systemImage: "mappin.circle.fill")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(sessionState.selectedEvent == nil)
                }
            }
            .sheet(isPresented: $showEventPicker) {
                EventPickerSheet()
            }
            .sheet(isPresented: $showDepartmentPicker) {
                DepartmentPickerSheet()
            }
            .sheet(isPresented: $showCreateSession) {
                CreateSessionSheet()
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostSheet()
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
        }
        .task {
            await sessionState.loadEvents()

            // Load attendance summary - provides session data dor check-in stats
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionState.selectedEvent?.name ?? "Select Event")
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
        }
        .buttonStyle(.plain)
    }

    // MARK: - Department Selector

    private var departmentSelector: some View {
        Button {
            showDepartmentPicker = true
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "building.2")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.themeColor)

                Text(sessionState.selectedDepartment?.name ?? "All Departments")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }
            .padding(.horizontal, AppTheme.Spacing.cardPadding)
            .padding(.vertical, AppTheme.Spacing.m)
            .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
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

                // Assignments overview
                assignmentsOverviewSection
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                // Check-in stats and attendance actions
                recentActivitySection
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }

    // MARK: - Empty State

    private var selectEventPrompt: some View {
        ContentUnavailableView(
            "No Event Selected",
            systemImage: "calendar",
            description: Text("Tap above to select an event to manage")
        )
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        LazyVGrid(columns: [.init(), .init()], spacing: AppTheme.Spacing.m) {
            StatCard(
                title: "Volunteers",
                value: "\(sessionState.selectedDepartment?.volunteerCount ?? sessionState.selectedEvent?.volunteerCount ?? 0)",
                icon: "person.3",
                colorScheme: colorScheme
            )
            StatCard(
                title: "Assignments",
                value: "—",
                icon: "calendar",
                colorScheme: colorScheme
            )
            StatCard(
                title: "Pending",
                value: "—",
                icon: "clock",
                colorScheme: colorScheme
            )
            StatCard(
                title: "Coverage",
                value: "—",
                icon: "chart.pie",
                colorScheme: colorScheme
            )
        }
    }

    // MARK: - Assignments Overview

    private var assignmentsOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            Text("Assignments Overview")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.themeColor)

            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("View the Assignments tab for coverage details")
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
            HStack(spacing: 8) {
                Image(systemName: "number")
                    .foregroundStyle(AppTheme.themeColor)
                Text("ATTENDANCE")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            NavigationLink(destination: AttendanceInputView()) {
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppTheme.themeColor)
                        .frame(width: 24)

                    Text("Submit Count")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .cornerRadius(AppTheme.CornerRadius.small)
            }
            .buttonStyle(.plain)

            NavigationLink(destination: AttendanceSummaryView()) {
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundStyle(AppTheme.themeColor)
                        .frame(width: 24)

                    Text("View Summary")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
                .cornerRadius(AppTheme.CornerRadius.small)
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
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(AppTheme.themeColor)

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

// MARK: - Recent Message Dashboard Row

private struct RecentMessageDashboardRow: View {
    let message: SentMessageItem
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Icon based on recipient type
            ZStack {
                Circle()
                    .fill(recipientColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: recipientIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(recipientColor)
            }

            // Message preview
            VStack(alignment: .leading, spacing: 4) {
                Text(message.subject ?? message.body)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(message.recipientTypeDisplayName)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            // Time ago
            Text(timeAgo)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
        .cornerRadius(AppTheme.CornerRadius.small)
    }

    private var recipientIcon: String {
        switch message.recipientType {
        case "VOLUNTEER": return "person"
        case "DEPARTMENT": return "person.3"
        case "EVENT": return "megaphone"
        default: return "envelope"
        }
    }

    private var recipientColor: Color {
        switch message.recipientType {
        case "VOLUNTEER": return AppTheme.themeColor
        case "DEPARTMENT": return .blue
        case "EVENT": return .purple
        default: return .gray
        }
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: message.createdAt, relativeTo: Date())
    }
}

#Preview {
    OverseerDashboardView()
}

#Preview("Dark Mode") {
    OverseerDashboardView()
        .preferredColorScheme(.dark)
}
