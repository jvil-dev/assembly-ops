//
//  EventHomeView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

// MARK: - Event Home View (Unified)
//
// Home tab for all users inside an event context.
// Shows event details, department tag, and role-specific content.
//
// Sections (all users):
//   - Settings circle (top-left toolbar)
//   - Event details banner (theme + type badge, venue, dates, volunteers)
//   - Department tag showing user's department + role
//
// Overseer sections:
//   - Today's schedule — posts with assigned volunteers for today's sessions
//
// Volunteer sections:
//   - Next Up card — current/upcoming assignment with check-in
//   - Today's Summary card — all today's assignments with status
//   - Action Items card — pending assignments and unread messages
//

import SwiftUI

struct EventHomeView: View {
    let membership: EventMembershipItem
    var switchToTab: ((EventTab) -> Void)? = nil

    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var coverageVM = CoverageMatrixViewModel()
    @StateObject private var homeVM = HomeViewModel()
    @ObservedObject private var messageBadgeManager = UnreadBadgeManager.shared
    @ObservedObject private var pendingBadgeManager = PendingBadgeManager.shared
    @State private var hasAppeared = false
    @State private var showSettings = false
    @State private var isCheckingIn = false
    @State private var now = Date()

    private var isOverseer: Bool {
        membership.membershipType == .overseer ||
        membership.hierarchyRole == "ASSISTANT_OVERSEER"
    }

    private var departmentColor: Color {
        if let deptType = membership.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    private var dateRangeString: String {
        DateUtils.formatEventFullDateRange(from: membership.startDate, to: membership.endDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Event details banner
                    eventDetailsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Department tag
                    if let deptName = membership.departmentName {
                        departmentTagCard(name: deptName)
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                    }

                    if isOverseer {
                        // Overseer: Today's coverage schedule
                        todaysAssignmentsSection
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)
                    } else {
                        // Volunteer: Next up + today's summary + action items
                        volunteerNextUpCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)

                        if homeVM.hasTodayAssignments {
                            volunteerTodaySummaryCard
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
                        }

                        if pendingBadgeManager.pendingCount > 0 || messageBadgeManager.unreadCount > 0 {
                            volunteerActionItemsCard
                                .entranceAnimation(hasAppeared: hasAppeared, delay: 0.20)
                        }
                    }
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle(membership.eventName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    settingsButton
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(appState)
            }
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .refreshable {
                if isOverseer {
                    await coverageVM.loadCoverage()
                } else {
                    await homeVM.refresh(eventId: membership.eventId)
                }
            }
            .task {
                if isOverseer {
                    coverageVM.departmentId = membership.departmentId
                    await coverageVM.loadCoverage()
                } else {
                    await homeVM.loadAssignments(eventId: membership.eventId)
                }
            }
        }
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button {
            showSettings = true
            HapticManager.shared.lightTap()
        } label: {
            ZStack {
                Circle()
                    .fill(AppTheme.themeColor.opacity(colorScheme == .dark ? 0.25 : 0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.themeColor)
            }
        }
    }

    // MARK: - Event Details Card

    private var eventDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Theme + Event Type badge
            Text(membership.themeBadgeText)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(departmentColor)
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(departmentColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

            // Info rows
            HStack(spacing: AppTheme.Spacing.l) {
                infoColumn(icon: "mappin.circle", text: membership.venue)
                Divider().frame(height: 32)
                infoColumn(icon: "calendar", text: dateRangeString)
                Divider().frame(height: 32)
                infoColumn(icon: "person.3", text: "\(membership.volunteerCount)")
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private func infoColumn(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Department Tag Card

    private func departmentTagCard(name: String) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(departmentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: departmentIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(departmentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Department")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text(name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text(isOverseer ? (membership.hierarchyRole == "ASSISTANT_OVERSEER" ? "Asst. Overseer" : "Overseer") : "Volunteer")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(departmentColor)
                .padding(.horizontal, AppTheme.Spacing.s)
                .padding(.vertical, 4)
                .background(departmentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Today's Assignments

    private var todaySessions: [CoverageSession] {
        let calendar = Calendar.current
        return coverageVM.sessions.filter { calendar.isDateInToday($0.date) }
    }

    @ViewBuilder
    private var todaysAssignmentsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(departmentColor)
                Text("Today's Schedule")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if coverageVM.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(departmentColor)
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.l)
            } else if todaySessions.isEmpty {
                noSessionsPlaceholder
            } else {
                ForEach(todaySessions) { session in
                    sessionAssignmentsCard(session: session)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var noSessionsPlaceholder: some View {
        HStack {
            Spacer()
            VStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "calendar.badge.minus")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text("No sessions scheduled for today")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.l)
    }

    private func sessionAssignmentsCard(session: CoverageSession) -> some View {
        let sessionSlots = coverageVM.slots(for: session.id)

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            // Session header
            HStack {
                Text(session.name)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("·")
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))

                Text(sessionTimeString(session))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))

                Spacer()

                // Fill status
                let totalAssigned = sessionSlots.reduce(0) { $0 + $1.filled }
                Text("\(totalAssigned) assigned")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(totalAssigned > 0
                        ? AppTheme.StatusColors.accepted
                        : AppTheme.StatusColors.pending)
            }
            .padding(.bottom, 2)

            // Post rows
            ForEach(sessionSlots, id: \.id) { slot in
                postRow(slot: slot)
            }
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.cardBackgroundSecondary(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }

    private func postRow(slot: CoverageSlot) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            // Fill indicator dot
            Circle()
                .fill(slot.filled > 0
                    ? AppTheme.StatusColors.accepted
                    : (slot.assignments.isEmpty ? AppTheme.StatusColors.declined : AppTheme.StatusColors.pending))
                .frame(width: 8, height: 8)

            // Post name
            VStack(alignment: .leading, spacing: 2) {
                Text(slot.postName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)

                // Volunteer names or unfilled indicator
                if slot.assignments.isEmpty {
                    Text("Unfilled")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.StatusColors.declined)
                } else {
                    Text(slot.assignments.map { volunteerDisplayName($0.volunteer) }.joined(separator: ", "))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Volunteer count
            Text("\(slot.filled)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(slot.filled > 0
                    ? AppTheme.StatusColors.accepted
                    : AppTheme.textTertiary(for: colorScheme))
        }
        .padding(.vertical, 2)
    }

    // MARK: - Volunteer Next Up Card

    @ViewBuilder
    private var volunteerNextUpCard: some View {
        Group {
            if homeVM.isLoading && homeVM.assignments.isEmpty {
                volunteerNextUpLoadingState
            } else if let active = homeVM.currentActiveAssignment {
                volunteerNextUpNowState(assignment: active)
            } else if let next = homeVM.nextUpAssignment {
                if next.isToday {
                    volunteerNextUpUpcomingState(assignment: next)
                } else {
                    volunteerNextUpAllDoneState
                }
            } else if homeVM.hasAnyAssignments {
                volunteerNextUpAllDoneState
            } else {
                volunteerNextUpEmptyState
            }
        }
    }

    private var volunteerNextUpLoadingState: some View {
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

    private func volunteerNextUpNowState(assignment: Assignment) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
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

            Button {
                Task {
                    isCheckingIn = true
                    await homeVM.checkOut(assignmentId: assignment.id)
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

    private func volunteerNextUpUpcomingState(assignment: Assignment) -> some View {
        NavigationLink(destination: AssignmentDetailView(assignment: assignment)) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack {
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "clock.badge")
                            .foregroundStyle(AppTheme.themeColor)
                        Text("home.nextUp".localized)
                            .font(AppTheme.Typography.captionBold)
                            .foregroundStyle(AppTheme.themeColor)
                    }
                    Spacer()
                    Text(homeVM.relativeTimeText(for: assignment))
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(AppTheme.StatusColors.pending)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.StatusColors.pendingBackground)
                        .clipShape(Capsule())
                }

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

                if assignment.canCheckIn {
                    Button {
                        Task {
                            isCheckingIn = true
                            await homeVM.checkIn(assignmentId: assignment.id)
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

    private var volunteerNextUpAllDoneState: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.StatusColors.accepted)

            Text("home.nextUp.allDone".localized)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let nextDate = homeVM.nextAssignmentDate {
                Text(String(format: "home.nextUp.nextDate".localized, DateUtils.eventFullDateFormatter.string(from: nextDate)))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    private var volunteerNextUpEmptyState: some View {
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

    // MARK: - Volunteer Today's Summary Card

    private var volunteerTodaySummaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(AppTheme.themeColor)
                Text("home.summary".localized)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(AppTheme.themeColor)
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                Text(String(format: "home.summary.count".localized, homeVM.todayTotal))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.primary)
                Text("•")
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Text(String(format: "home.summary.completed".localized, homeVM.todayCompleted))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }

            Divider()

            ForEach(homeVM.todayAssignments) { assignment in
                HStack(spacing: AppTheme.Spacing.s) {
                    volunteerAssignmentStatusIcon(for: assignment)
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

                    Text(volunteerAssignmentStatusText(for: assignment))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(volunteerAssignmentStatusColor(for: assignment))
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    @ViewBuilder
    private func volunteerAssignmentStatusIcon(for assignment: Assignment) -> some View {
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

    private func volunteerAssignmentStatusText(for assignment: Assignment) -> String {
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

    private func volunteerAssignmentStatusColor(for assignment: Assignment) -> Color {
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

    // MARK: - Volunteer Action Items Card

    private var volunteerActionItemsCard: some View {
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

    // MARK: - Overseer Helpers

    private func volunteerDisplayName(_ v: CoverageVolunteer) -> String {
        "\(v.firstName) \(v.lastName.prefix(1))."
    }

    private func sessionTimeString(_ session: CoverageSession) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: session.startTime)
    }

    private var departmentIcon: String {
        guard let type = membership.departmentType else { return "building.2" }
        switch type.uppercased() {
        case "PARKING": return "car"
        case "ATTENDANT": return "person.badge.shield.checkmark"
        case "AUDIO": return "speaker.wave.3"
        case "VIDEO": return "video"
        case "STAGE": return "light.overhead.left"
        case "CLEANING": return "sparkles"
        case "COMMITTEE": return "person.3"
        case "FIRST_AID", "FIRSTAID": return "cross"
        case "BAPTISM": return "drop"
        case "INFORMATION", "INFORMATION_VOLUNTEER_SERVICE": return "info.circle"
        case "ACCOUNTS": return "dollarsign.circle"
        case "INSTALLATION": return "hammer"
        case "LOST_FOUND", "LOST_AND_FOUND", "LOST_FOUND_CHECKROOM": return "tray"
        case "ROOMING": return "bed.double"
        case "TRUCKING", "TRUCKING_EQUIPMENT": return "truck.box"
        default: return "building.2"
        }
    }
}

#Preview {
    EventHomeView(
        membership: EventMembershipItem(
            id: "1", eventId: "1",
            eventName: "2026 Circuit Assembly",
            eventType: "CIRCUIT_ASSEMBLY_CO",
            theme: "Declare the Good News!",
            venue: "Assembly Hall", address: "123 Main St",
            startDate: Date(), endDate: Date().addingTimeInterval(86400 * 2),
            volunteerCount: 45, membershipType: .overseer,
            overseerRole: "DEPARTMENT_OVERSEER",
            departmentId: "d1", departmentName: "Attendant",
            departmentType: "ATTENDANT",
            departmentAccessCode: "ABC123",
            eventVolunteerId: nil, volunteerId: nil,
            hierarchyRole: nil
        )
    )
    .environmentObject(AppState.shared)
}
