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
import Combine

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
    @State private var showWalkThrough = false
    @State private var attendantPosts: [AttendantPostItem] = []
    @State private var sessions: [VolunteerSessionItem] = []
    @State private var isCheckingIn = false
    @State private var now = Date()

    private let concernsTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    /// Event ID passed from EventTabView for reliable data fetching
    var eventId: String? = nil

    /// Closure to switch the parent tab view to a specific tab
    var switchToTab: ((EventTab) -> Void)?

    private var isAttendant: Bool {
        viewModel.assignments.contains { $0.departmentType == "ATTENDANT" }
    }

    private var isCaptain: Bool {
        viewModel.assignments.contains { $0.isCaptain && $0.isAccepted }
    }

    private var isAttendantCaptain: Bool {
        viewModel.assignments.contains { $0.isCaptain && $0.isAccepted && $0.departmentType == "ATTENDANT" }
    }

    private var hasActionItems: Bool {
        pendingBadgeManager.pendingCount > 0 || messageBadgeManager.unreadCount > 0
    }

    private var currentSessionId: String? {
        let now = Date()
        return sessions.first(where: { session in
            session.startTime <= now && session.endTime >= now
        })?.id ?? sessions.first?.id
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

                    // 5. Attendant section (only for attendant dept)
                    if isAttendant {
                        attendantCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.20)

                        // Seating status overview (read-only for all attendants)
                        if !attendantVM.postSessionStatuses.isEmpty {
                            seatingStatusCard
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.25)
                        }

                        // Facility locations
                        if !attendantVM.facilityLocations.isEmpty {
                            facilityLocationsCard
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.30)
                        }
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
                if isAttendant && isAttendantCaptain {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showWalkThrough = true
                            HapticManager.shared.lightTap()
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "checklist")
                                if let sid = currentSessionId, attendantVM.hasCompletedWalkThrough(for: sid) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppTheme.StatusColors.accepted)
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }
                        .disabled(sessions.isEmpty)
                    }
                }
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .task {
                await viewModel.loadAssignments(eventId: eventId)
                if isAttendant {
                    await loadAttendantPosts()
                    if let eventId = appState.currentEventId {
                        await attendantVM.loadConcerns(eventId: eventId)
                        await attendantVM.loadFacilityLocations(eventId: eventId)
                        if let sid = currentSessionId {
                            await attendantVM.loadPostSessionStatuses(sessionId: sid)
                        }
                        if isAttendantCaptain {
                            sessions = (try? await AttendanceService.shared.fetchVolunteerSessions(eventId: eventId)) ?? []
                            await attendantVM.loadMyWalkThroughCompletions()
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refresh(eventId: eventId)
                if isAttendant {
                    await loadAttendantPosts()
                    if let eventId = eventId ?? appState.currentEventId {
                        await attendantVM.loadConcerns(eventId: eventId)
                        await attendantVM.loadFacilityLocations(eventId: eventId)
                        if let sid = currentSessionId {
                            await attendantVM.loadPostSessionStatuses(sessionId: sid)
                        }
                        if isAttendantCaptain {
                            sessions = (try? await AttendanceService.shared.fetchVolunteerSessions(eventId: eventId)) ?? []
                            await attendantVM.loadMyWalkThroughCompletions()
                        }
                    }
                }
            }
            .onReceive(concernsTimer) { date in
                if isAttendant { now = date }
            }
            .sheet(isPresented: $showReportIncident) {
                ReportSafetyIncidentView(
                    posts: attendantPosts,
                    currentSessionId: currentSessionId,
                    onDidReport: {
                        if let eventId = appState.currentEventId {
                            await attendantVM.loadConcerns(eventId: eventId)
                        }
                    }
                )
            }
            .sheet(isPresented: $showReportLostPerson) {
                ReportLostPersonView(
                    posts: attendantPosts,
                    currentSessionId: currentSessionId,
                    onDidReport: {
                        if let eventId = appState.currentEventId {
                            await attendantVM.loadConcerns(eventId: eventId)
                        }
                    }
                )
            }
            .sheet(isPresented: $showAttendantInfo) {
                AttendantInfoView()
            }
            .sheet(isPresented: $showWalkThrough) {
                WalkThroughChecklistView(attendantVM: attendantVM, sessions: sessions)
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            if let firstName = appState.currentUser?.firstName {
                Text(String(format: "home.welcome".localized, firstName))
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundStyle(.primary)
            }

            HStack(spacing: AppTheme.Spacing.s) {
                if let deptType = viewModel.assignments.first?.departmentType {
                    Circle()
                        .fill(DepartmentColor.color(for: deptType))
                        .frame(width: 8, height: 8)
                }

                if let department = viewModel.assignments.first?.departmentName {
                    Text(department)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                if let appointment = appState.currentUser?.appointmentStatus {
                    Text("•")
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text(formatAppointment(appointment))
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                if isCaptain {
                    Text("•")
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("home.role.captain".localized)
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.themeColor)
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
            HStack(spacing: AppTheme.Spacing.s) {
                Circle()
                    .fill(AppTheme.StatusColors.accepted)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .fill(AppTheme.StatusColors.accepted.opacity(0.3))
                            .frame(width: 20, height: 20)
                    )
                Text("home.nextUp.now".localized)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(AppTheme.StatusColors.accepted)
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
                .background(AppTheme.StatusColors.accepted)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
            }
            .buttonStyle(.plain)
            .disabled(isCheckingIn)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .strokeBorder(AppTheme.StatusColors.accepted.opacity(0.3), lineWidth: 1)
        )
    }

    /// Upcoming state — next assignment coming up today
    private func nextUpUpcomingState(assignment: Assignment) -> some View {
        NavigationLink(destination: AssignmentDetailView(assignment: assignment)) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                // Header
                HStack {
                    HStack(spacing: AppTheme.Spacing.s) {
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
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                    }
                    .buttonStyle(.plain)
                    .disabled(isCheckingIn)
                } else {
                    HStack {
                        Spacer()
                        HStack(spacing: AppTheme.Spacing.xs) {
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
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("home.summary".localized)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(AppTheme.themeColor)
            }

            // Stats row
            HStack(spacing: AppTheme.Spacing.xs) {
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
                .foregroundStyle(AppTheme.StatusColors.accepted)
                .font(.system(size: 16))
        } else if assignment.isCheckedOut {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(AppTheme.StatusColors.info)
                .font(.system(size: 16))
        } else if assignment.canCheckIn {
            Image(systemName: "circle.dashed")
                .foregroundStyle(AppTheme.StatusColors.pending)
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
            return AppTheme.StatusColors.accepted
        } else if assignment.isCheckedOut {
            return AppTheme.StatusColors.info
        } else if assignment.canCheckIn {
            return AppTheme.StatusColors.pending
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
                    switchToTab?(.assignments)
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

                        HStack(spacing: AppTheme.Spacing.xs) {
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

                        HStack(spacing: AppTheme.Spacing.xs) {
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

    // MARK: - Attendant Card

    private var attendantCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            // Section header
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "shield.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("attendant.concerns.report".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Report buttons
            HStack(spacing: AppTheme.Spacing.m) {
                Button {
                    showReportIncident = true
                    HapticManager.shared.lightTap()
                } label: {
                    Label("attendant.home.reportIncident".localized, systemImage: "exclamationmark.triangle.fill")
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.StatusColors.warning)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.m)
                        .background(AppTheme.StatusColors.warning.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
                .buttonStyle(.plain)

                Button {
                    showReportLostPerson = true
                    HapticManager.shared.lightTap()
                } label: {
                    Label("attendant.home.reportLostPerson".localized, systemImage: "person.crop.circle.badge.questionmark")
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.StatusColors.declined)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.m)
                        .background(AppTheme.StatusColors.declined.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Concerns feed header
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "exclamationmark.bubble")
                    .foregroundStyle(AppTheme.themeColor)
                Text("attendant.concerns.title".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                let unresolvedCount = attendantVM.concerns.filter { !$0.isResolved }.count
                if unresolvedCount > 0 {
                    Text("\(unresolvedCount)")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.StatusColors.declined)
                        .clipShape(Capsule())
                }
            }

            if attendantVM.isLoading && attendantVM.concerns.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.m)
            } else if attendantVM.concerns.isEmpty {
                Text("attendant.concerns.empty".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppTheme.Spacing.s)
            } else {
                ForEach(attendantVM.concerns) { concern in
                    NavigationLink(destination: VolunteerConcernDetailView(concern: concern)) {
                        concernRow(concern)
                    }
                    .buttonStyle(.plain)

                    if concern.id != attendantVM.concerns.last?.id {
                        Divider()
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    @ViewBuilder
    private func concernRow(_ concern: ConcernItem) -> some View {
        switch concern {
        case .incident(let incident):
            homeConcernRow(
                icon: incident.type.icon,
                iconColor: incident.resolved ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.warning,
                title: incident.type.displayName,
                subtitle: incident.description,
                location: incident.location ?? incident.postName,
                resolved: incident.resolved,
                activeColor: AppTheme.StatusColors.warning,
                timestamp: DateUtils.timeAgo(from: incident.createdAt),
                elapsedTimer: nil
            )
        case .alert(let alert):
            homeConcernRow(
                icon: "person.crop.circle.badge.questionmark",
                iconColor: alert.resolved ? AppTheme.StatusColors.accepted : AppTheme.StatusColors.declined,
                title: alert.personName,
                subtitle: alert.description,
                location: alert.lastSeenLocation,
                resolved: alert.resolved,
                activeColor: AppTheme.StatusColors.declined,
                timestamp: DateUtils.timeAgo(from: alert.createdAt),
                elapsedTimer: DateUtils.elapsedString(from: alert.createdAt, to: alert.resolvedAt ?? now)
            )
        }
    }

    private func homeConcernRow(
        icon: String, iconColor: Color, title: String, subtitle: String,
        location: String?, resolved: Bool, activeColor: Color,
        timestamp: String, elapsedTimer: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .lineLimit(2)
                }
                Spacer()
                if resolved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.StatusColors.accepted)
                        .font(.system(size: 14))
                } else {
                    Circle()
                        .fill(activeColor)
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)
                }
            }

            HStack {
                if let location {
                    Label(location, systemImage: "mappin")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
                Spacer()
                if let elapsed = elapsedTimer {
                    Label(elapsed, systemImage: "timer")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(activeColor)
                } else {
                    Text(timestamp)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    // MARK: - Seating Status Card (Read-Only)

    private var seatingStatusCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "chair.lounge")
                    .foregroundStyle(AppTheme.themeColor)
                Text("attendant.seating.title".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            ForEach(attendantVM.postSessionStatuses) { status in
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: status.status.icon)
                        .foregroundStyle(status.status.color)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.postName)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(.primary)
                        if let location = status.postLocation {
                            Text(location)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                    }
                    Spacer()
                    Text(status.status.displayName)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(status.status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status.status.color.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Facility Guide Card (Read-Only)

    private var facilityLocationsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "building.2")
                    .foregroundStyle(AppTheme.themeColor)
                Text("attendant.facility.title".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            ForEach(attendantVM.facilityLocations) { facility in
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(AppTheme.themeColor)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(facility.name)
                            .font(AppTheme.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Text(facility.location)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        if let desc = facility.description {
                            Text(desc)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Helpers

    private func formatAppointment(_ status: String) -> String {
        switch status.uppercased() {
        case "ELDER": return "home.role.elder".localized
        case "MINISTERIAL_SERVANT": return "home.role.ministerialServant".localized
        case "PUBLISHER": return "home.role.publisher".localized
        default: return status
        }
    }

    // MARK: - Data Loading

    /// Derive attendant posts from the volunteer's accepted assignments
    private func loadAttendantPosts() async {
        guard let eventId = appState.currentEventId else { return }
        if let assignments = try? await AssignmentsService.shared.fetchAssignments(eventId: eventId) {
            let unique = Dictionary(
                assignments
                    .filter { $0.status == .accepted && $0.departmentType == "ATTENDANT" }
                    .map { ($0.postId, AttendantPostItem(id: $0.postId, name: $0.postName, location: $0.postLocation, category: $0.postCategory, sortOrder: 0)) },
                uniquingKeysWith: { first, _ in first }
            )
            attendantPosts = Array(unique.values).sorted {
                let idx0 = AttendantMainCategory.sortIndex(for: $0.category ?? "")
                let idx1 = AttendantMainCategory.sortIndex(for: $1.category ?? "")
                if idx0 != idx1 { return idx0 < idx1 }
                return $0.name < $1.name
            }
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
