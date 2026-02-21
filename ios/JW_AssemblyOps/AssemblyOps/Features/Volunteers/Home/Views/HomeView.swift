//
//  HomeView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 12/27/25.
//

// MARK: - Home View
//
// "At a Glance" dashboard showing volunteers exactly what they need to know
// right now — next assignment, today's progress, and action items.
//
// Components (unified for all volunteers):
//   - Welcome header: Name, department, event theme
//   - Next Up card: Current/upcoming assignment with check-in action
//   - Today's Summary card: Status of all today's assignments
//   - Action Items card: Pending assignments and unread messages
//   - Quick Actions row: Report incident/lost person (attendant only)
//
// Features:
//   - Warm gradient background matching app design system
//   - Floating cards with layered shadows
//   - Staggered entrance animations
//   - Pull to refresh support
//   - Auto-updating relative time ("in 45 min")
//   - Cross-tab navigation to Schedule/Messages
//
// Dependencies:
//   - HomeViewModel: Assignment data, check-in actions, relative time
//   - AppState: Current volunteer and event info
//   - AppTheme: Design system tokens
//   - AttendantVolunteerViewModel: Meetings data for attendant report sheets

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var attendantVM = AttendantVolunteerViewModel()
    @ObservedObject private var messageBadgeManager = UnreadBadgeManager.shared
    @ObservedObject private var pendingBadgeManager = PendingBadgeManager.shared
    @State private var hasAppeared = false
    @State private var showReportIncident = false
    @State private var showReportLostPerson = false
    @State private var showAttendantInfo = false
    @State private var attendantPosts: [AttendantPostItem] = []
    @State private var isCheckingIn = false

    /// Closure to switch the parent tab view to a specific tab
    var switchToTab: ((VolunteerTab) -> Void)?

    private var isAttendant: Bool {
        appState.currentVolunteer?.departmentType == "ATTENDANT"
    }

    private var hasActionItems: Bool {
        pendingBadgeManager.pendingCount > 0 || messageBadgeManager.unreadCount > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // 1. Welcome header
                    welcomeHeader
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // 2. Next Up card
                    nextUpCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // 3. Today's Summary (only if assignments today)
                    if viewModel.hasTodayAssignments {
                        todaySummaryCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)
                    }

                    // 4. Action Items (only if pending or unread)
                    if hasActionItems {
                        actionItemsCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                    }

                    // 5. Attendant Quick Actions (only for attendant dept)
                    if isAttendant {
                        attendantQuickActionsRow
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.20)
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("tab.home".localized)
            .toolbar {
                if isAttendant {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAttendantInfo = true
                            HapticManager.shared.lightTap()
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                    }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .task {
                await viewModel.loadAssignments()
                if isAttendant {
                    await loadAttendantPosts()
                }
            }
            .refreshable {
                await viewModel.refresh()
                if isAttendant {
                    await loadAttendantPosts()
                }
            }
            .sheet(isPresented: $showReportIncident) {
                ReportSafetyIncidentView(posts: attendantPosts)
            }
            .sheet(isPresented: $showReportLostPerson) {
                ReportLostPersonView(posts: attendantPosts)
            }
            .sheet(isPresented: $showAttendantInfo) {
                AttendantInfoView()
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            if let firstName = appState.currentVolunteer?.firstName {
                Text(String(format: "home.welcome".localized, firstName))
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 8) {
                if let deptType = appState.currentVolunteer?.departmentType {
                    Circle()
                        .fill(DepartmentColor.color(for: deptType))
                        .frame(width: 8, height: 8)
                }

                if let department = appState.currentVolunteer?.departmentName {
                    Text(department)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                if appState.currentVolunteer?.eventTheme != nil {
                    Text("•")
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                if let theme = appState.currentVolunteer?.eventTheme {
                    Text(theme)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Next Up Card

    private var nextUpCard: some View {
        Group {
            if viewModel.isLoading && viewModel.assignments.isEmpty {
                nextUpLoadingState
            } else if let active = viewModel.currentActiveAssignment {
                nextUpNowState(assignment: active)
            } else if let next = viewModel.nextUpAssignment {
                if next.isToday {
                    nextUpUpcomingState(assignment: next)
                } else {
                    nextUpAllDoneState
                }
            } else if viewModel.hasAnyAssignments {
                nextUpAllDoneState
            } else {
                nextUpEmptyState
            }
        }
    }

    /// Loading state
    private var nextUpLoadingState: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            ProgressView()
            Text("Loading...")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    /// NOW state — currently checked in to an assignment
    private func nextUpNowState(assignment: Assignment) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // NOW badge
            HStack(spacing: 8) {
                Circle()
                    .fill(.green)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .fill(.green.opacity(0.3))
                            .frame(width: 20, height: 20)
                    )
                Text("home.nextUp.now".localized)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(.green)
            }

            // Assignment info
            Text(assignment.postName)
                .font(AppTheme.Typography.title)
                .foregroundStyle(.primary)

            if let location = assignment.postLocation {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text(location)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text("\(assignment.sessionName) • \(assignment.timeRangeFormatted)")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            // Check Out button
            Button {
                Task {
                    isCheckingIn = true
                    await viewModel.checkOut(assignmentId: assignment.id)
                    isCheckingIn = false
                }
            } label: {
                HStack {
                    if isCheckingIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("home.nextUp.checkOut".localized)
                    }
                }
                .font(AppTheme.Typography.bodyMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.m)
                .background(.green)
                .cornerRadius(AppTheme.CornerRadius.button)
            }
            .buttonStyle(.plain)
            .disabled(isCheckingIn)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .strokeBorder(.green.opacity(0.3), lineWidth: 1)
        )
    }

    /// Upcoming state — next assignment coming up today
    private func nextUpUpcomingState(assignment: Assignment) -> some View {
        NavigationLink(destination: AssignmentDetailView(assignment: assignment)) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.badge")
                            .foregroundStyle(AppTheme.themeColor)
                        Text("home.nextUp".localized)
                            .font(AppTheme.Typography.captionBold)
                            .foregroundStyle(AppTheme.themeColor)
                    }
                    Spacer()
                    Text(viewModel.relativeTimeText(for: assignment))
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(AppTheme.StatusColors.pending)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.StatusColors.pendingBackground)
                        .clipShape(Capsule())
                }

                // Assignment info
                Text(assignment.postName)
                    .font(AppTheme.Typography.title)
                    .foregroundStyle(.primary)

                if let location = assignment.postLocation {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        Text(location)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("\(assignment.sessionName) • \(assignment.timeRangeFormatted)")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                // Check In button (if ready) or View Details
                if assignment.canCheckIn {
                    Button {
                        Task {
                            isCheckingIn = true
                            await viewModel.checkIn(assignmentId: assignment.id)
                            isCheckingIn = false
                        }
                    } label: {
                        HStack {
                            if isCheckingIn {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("home.nextUp.checkIn".localized)
                            }
                        }
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.m)
                        .background(AppTheme.themeColor)
                        .cornerRadius(AppTheme.CornerRadius.button)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCheckingIn)
                } else {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Text("home.nextUp.viewDetails".localized)
                                .font(AppTheme.Typography.caption)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.themeColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    /// All done state — all today's assignments completed
    private var nextUpAllDoneState: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.StatusColors.accepted)

            Text("home.nextUp.allDone".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let nextDate = viewModel.nextAssignmentDate {
                let formatter = DateFormatter()
                let _ = formatter.dateStyle = .medium
                Text(String(format: "home.nextUp.nextDate".localized, formatter.string(from: nextDate)))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    /// Empty state — no assignments at all
    private var nextUpEmptyState: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

            Text("home.nextUp.noAssignments".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)

            Text("home.nextUp.noAssignments.subtitle".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Today's Summary Card

    private var todaySummaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("home.summary".localized)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(AppTheme.themeColor)
            }

            // Stats row
            HStack(spacing: 4) {
                Text(String(format: "home.summary.count".localized, viewModel.todayTotal))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)
                Text("•")
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text(String(format: "home.summary.completed".localized, viewModel.todayCompleted))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            // Assignment status list
            Divider()

            ForEach(viewModel.todayAssignments) { assignment in
                HStack(spacing: AppTheme.Spacing.s) {
                    assignmentStatusIcon(for: assignment)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(assignment.postName)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.primary)
                        Text("\(assignment.sessionName) • \(assignment.timeRangeFormatted)")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }

                    Spacer()

                    Text(assignmentStatusText(for: assignment))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(assignmentStatusColor(for: assignment))
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    @ViewBuilder
    private func assignmentStatusIcon(for assignment: Assignment) -> some View {
        if assignment.isCheckedIn {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 16))
        } else if assignment.isCheckedOut {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 16))
        } else if assignment.canCheckIn {
            Image(systemName: "circle.dashed")
                .foregroundStyle(.orange)
                .font(.system(size: 16))
        } else {
            Image(systemName: "clock")
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .font(.system(size: 16))
        }
    }

    private func assignmentStatusText(for assignment: Assignment) -> String {
        if assignment.isCheckedIn {
            return "home.summary.checkedIn".localized
        } else if assignment.isCheckedOut {
            return "home.summary.done".localized
        } else if assignment.canCheckIn {
            return "home.summary.ready".localized
        } else {
            return "home.summary.upcoming".localized
        }
    }

    private func assignmentStatusColor(for assignment: Assignment) -> Color {
        if assignment.isCheckedIn {
            return .green
        } else if assignment.isCheckedOut {
            return .blue
        } else if assignment.canCheckIn {
            return .orange
        } else {
            return AppTheme.textTertiary(for: colorScheme)
        }
    }

    // MARK: - Action Items Card

    private var actionItemsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            if pendingBadgeManager.pendingCount > 0 {
                Button {
                    HapticManager.shared.lightTap()
                    switchToTab?(.schedule)
                } label: {
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(AppTheme.StatusColors.warning)
                            .font(.system(size: 18))

                        let count = pendingBadgeManager.pendingCount
                        Text(count == 1
                             ? "home.actions.pendingOne".localized
                             : String(format: "home.actions.pending".localized, count))
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.primary)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("home.actions.respond".localized)
                                .font(AppTheme.Typography.caption)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.themeColor)
                    }
                }
                .buttonStyle(.plain)
            }

            if pendingBadgeManager.pendingCount > 0 && messageBadgeManager.unreadCount > 0 {
                Divider()
            }

            if messageBadgeManager.unreadCount > 0 {
                Button {
                    HapticManager.shared.lightTap()
                    switchToTab?(.messages)
                } label: {
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "envelope.badge.fill")
                            .foregroundStyle(AppTheme.StatusColors.info)
                            .font(.system(size: 18))

                        let count = messageBadgeManager.unreadCount
                        Text(count == 1
                             ? "home.actions.unreadOne".localized
                             : String(format: "home.actions.unread".localized, count))
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.primary)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("home.actions.read".localized)
                                .font(AppTheme.Typography.caption)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.themeColor)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Attendant Quick Actions

    private var attendantQuickActionsRow: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Button {
                showReportIncident = true
                HapticManager.shared.lightTap()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)
                    Text("attendant.home.reportIncident".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackground(for: colorScheme))
                .cornerRadius(AppTheme.CornerRadius.small)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            Button {
                showReportLostPerson = true
                HapticManager.shared.lightTap()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 16))
                        .foregroundStyle(.red)
                    Text("attendant.home.reportLostPerson".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.m)
                .background(AppTheme.cardBackground(for: colorScheme))
                .cornerRadius(AppTheme.CornerRadius.small)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Data Loading

    /// Derive attendant posts from the volunteer's accepted assignments
    private func loadAttendantPosts() async {
        if let assignments = try? await AssignmentsService.shared.fetchAssignments() {
            let unique = Dictionary(
                assignments
                    .filter { $0.status == .accepted && $0.departmentType == "ATTENDANT" }
                    .map { ($0.postId, AttendantPostItem(id: $0.postId, name: $0.postName, location: $0.postLocation, category: "", sortOrder: 0)) },
                uniquingKeysWith: { first, _ in first }
            )
            attendantPosts = Array(unique.values).sorted { $0.name < $1.name }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState.shared)
}

#Preview("Dark Mode") {
    HomeView()
        .environmentObject(AppState.shared)
        .preferredColorScheme(.dark)
}
