//
//  DepartmentTabRouter.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/26/26.
//

// MARK: - Department Tab Router
//
// Routes to the correct department-specific view based on department type
// and user role. This is the content view for the Department tab in EventTabView.
//
// Routing:
//   - Attendant (Overseer) → AttendantDashboardView
//   - Attendant (Volunteer) → AttendantVolunteerDeptView
//   - Audio (Overseer) → AudioDashboardView
//   - Audio (Volunteer) → AudioVolunteerDeptView
//   - Video (Overseer) → VideoDashboardView
//   - Video (Volunteer) → VideoVolunteerDeptView
//   - Stage (Overseer) → StageDashboardView
//   - Stage (Volunteer) → StageVolunteerDeptView
//   - All other depts → GenericDepartmentView (placeholder)
//
// The overseer's department view includes volunteer management, settings,
// check-in stats, join requests, and access code display.
// The volunteer's department view shows department-specific features
// (e.g. report incident for attendant dept).
//

import SwiftUI
import Apollo

struct DepartmentTabRouter: View {
    let membership: EventMembershipItem

    @EnvironmentObject private var appState: AppState
    @ObservedObject private var sessionState = EventSessionState.shared

    private var isOverseer: Bool {
        membership.membershipType == .overseer ||
        membership.hierarchyRole == "ASSISTANT_OVERSEER"
    }

    private var departmentType: String? {
        membership.departmentType ?? sessionState.selectedDepartment?.departmentType
    }

    var body: some View {
        NavigationStack {
            Group {
                if let deptType = departmentType {
                switch deptType.uppercased() {
                case "ATTENDANT":
                    if isOverseer {
                        AttendantDashboardView()
                    } else {
                        attendantVolunteerView(membership: membership)
                    }
                case "AUDIO":
                    if isOverseer {
                        AudioDashboardView()
                    } else {
                        AudioVolunteerDeptView()
                            .environmentObject(appState)
                    }
                case "VIDEO":
                    if isOverseer {
                        VideoDashboardView()
                    } else {
                        VideoVolunteerDeptView()
                            .environmentObject(appState)
                    }
                case "STAGE":
                    if isOverseer {
                        StageDashboardView()
                    } else {
                        StageVolunteerDeptView()
                            .environmentObject(appState)
                    }
                default:
                    GenericDepartmentView(membership: membership)
                }
                } else {
                    noDepartmentView
                }
            }
        }
    }

    // MARK: - Attendant Volunteer View

    /// Wraps existing attendant volunteer features into a scrollable department tab.
    private func attendantVolunteerView(membership: EventMembershipItem) -> some View {
        AttendantVolunteerDeptView(
            eventId: membership.eventId,
            departmentId: membership.departmentId,
            departmentType: membership.departmentType
        )
        .environmentObject(appState)
    }

    // MARK: - No Department

    private var noDepartmentView: some View {
        ContentUnavailableView(
            "No Department",
            systemImage: "building.2",
            description: Text("You haven't joined a department for this event yet.")
        )
    }
}

#Preview {
    DepartmentTabRouter(
        membership: EventMembershipItem(
            id: "1", eventId: "1",
            eventName: "2026 Circuit Assembly",
            eventType: "CIRCUIT_ASSEMBLY_CO",
            theme: nil,
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

// MARK: - Attendant Volunteer Department View

/// Container view surfacing all attendant volunteer features as the department tab content.
/// Replaces the sheet-based presentation from the old HomeView.
struct AttendantVolunteerDeptView: View {
    let eventId: String
    let departmentId: String?
    let departmentType: String?

    @EnvironmentObject private var appState: AppState
    @StateObject private var attendantVM = AttendantVolunteerViewModel()
    @StateObject private var reminderVM = ShiftReminderViewModel()
    @StateObject private var lanyardVM = LanyardViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var sessions: [VolunteerSessionItem] = []
    @State private var hasLoaded = false
    @State private var showReportIncident = false
    @State private var showReportLostPerson = false
    @State private var showAttendantInfo = false
    @State private var showWalkThrough = false
    @State private var isCaptain = false
    @State private var showReminderModal = false
    @State private var pendingReminderShift: (id: String, name: String)?
    @State private var isLanyardUrgent = false
    @State private var showLanyardUrgentAlert = false
    @State private var attendanceReminders: [AttendanceReminderItem] = []

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Lanyard Reminder Banner
                LanyardReminderBanner(status: lanyardVM.myStatus, isUrgent: isLanyardUrgent)
                    .environmentObject(appState)

                // Attendance Count Reminder Banner
                AttendanceCountReminderBanner(reminders: attendanceReminders)

                // Captain Scheduling & Attendance (visible only for captains)
                if isCaptain {
                    captainSchedulingCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    captainAttendanceCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)
                }

                // Quick Actions
                quickActionsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: isCaptain ? 0.10 : 0)

                // Meetings
                meetingsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: isCaptain ? 0.15 : 0.05)

                // Info & Protocol
                resourcesCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: isCaptain ? 0.20 : 0.10)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReportIncident) {
            ReportSafetyIncidentView()
        }
        .sheet(isPresented: $showReportLostPerson) {
            ReportLostPersonView()
        }
        .sheet(isPresented: $showAttendantInfo) {
            AttendantInfoView()
        }
        .sheet(isPresented: $showWalkThrough) {
            WalkThroughChecklistView(attendantVM: attendantVM, sessions: sessions)
        }
        .alert("lanyard.urgent.title".localized, isPresented: $showLanyardUrgentAlert) {
            Button("lanyard.urgent.dismiss".localized, role: .cancel) {}
        } message: {
            Text("lanyard.urgent.alertMessage".localized)
        }
        .fullScreenCover(isPresented: $showReminderModal) {
            if let shift = pendingReminderShift {
                ShiftReminderModal(
                    shiftId: shift.id,
                    shiftName: shift.name,
                    viewModel: reminderVM
                )
            }
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            await attendantVM.loadMyMeetings(eventId: eventId)
            do {
                sessions = try await AttendanceService.shared.fetchVolunteerSessions(eventId: eventId)
            } catch {
                print("[AttendantDept] Failed to load sessions: \(error)")
            }

            // Check if user is a captain (via accepted area captain assignments or isCaptain on post)
            var assignmentSessionIds: Set<String> = []
            do {
                async let postAssignmentsResult = NetworkClient.shared.apollo.fetch(
                    query: AssemblyOpsAPI.MyAssignmentsQuery(eventId: eventId),
                    cachePolicy: .fetchIgnoringCacheData
                )
                async let captainAssignmentsResult = AssignmentsService.shared.fetchCaptainAssignments(eventId: eventId)

                let (postResult, captainResults) = try await (postAssignmentsResult, captainAssignmentsResult)

                var hasCaptainRole = false
                if let assignments = postResult.data?.myAssignments {
                    hasCaptainRole = assignments.contains { $0.isCaptain }
                    for a in assignments where a.post.department.departmentType == .case(.attendant) {
                        assignmentSessionIds.insert(a.session.id)
                    }
                }

                // Also check for ACCEPTED area captain assignments
                if !hasCaptainRole {
                    hasCaptainRole = captainResults.contains { $0.status == .accepted }
                }

                isCaptain = hasCaptainRole
            } catch {
                print("[AttendantDept] Failed to check captain status: \(error)")
            }

            // Load reminder confirmations and check for unconfirmed shifts
            await reminderVM.loadMyConfirmations(eventId: eventId)
            await checkForPendingReminders(sessionIds: assignmentSessionIds)

            // Load lanyard status and check urgency
            await lanyardVM.loadMyStatus(eventId: eventId)
            checkLanyardUrgency()

            // Check attendance count submission status
            await checkAttendanceReminders()
        }
    }

    // MARK: - Attendance Reminder Check

    /// Checks if the volunteer has unsubmitted attendance counts for sessions
    /// ending within 30 minutes.
    private func checkAttendanceReminders() async {
        do {
            let statuses = try await AttendantService.shared.fetchMyAttendanceStatus(eventId: eventId)
            let now = Date()
            let reminders = statuses
                .filter { !$0.hasSubmitted }
                .filter { status in
                    let minutesUntilEnd = status.sessionEndTime.timeIntervalSince(now) / 60
                    return minutesUntilEnd <= 30 && minutesUntilEnd > -30 // Within 30 min window
                }
                .map { status in
                    AttendanceReminderItem(
                        id: status.sessionId,
                        sessionName: status.sessionName,
                        postId: status.postId,
                        postName: status.postName,
                        sessionEndTime: status.sessionEndTime
                    )
                }
            attendanceReminders = reminders
        } catch {
            print("[AttendantDept] Failed to check attendance status: \(error)")
        }
    }

    // MARK: - Lanyard Urgency Check

    /// Checks if the lanyard has not been picked up and the volunteer's first shift/session
    /// starts within 15 minutes. Shows urgent banner + alert if so.
    private func checkLanyardUrgency() {
        // Only check if lanyard is not picked up
        let lanyardNotPickedUp: Bool
        if let status = lanyardVM.myStatus {
            lanyardNotPickedUp = status.status == .notPickedUp
        } else {
            lanyardNotPickedUp = true // No record means not picked up
        }
        guard lanyardNotPickedUp else { return }

        // Find the earliest session start time for today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todaySessions = sessions.filter { session in
            calendar.isDate(session.date, inSameDayAs: today)
        }

        guard let earliestSession = todaySessions.min(by: { $0.startTime < $1.startTime }) else { return }

        let now = Date()
        let minutesUntilStart = earliestSession.startTime.timeIntervalSince(now) / 60

        // Urgent if within 15 minutes of first session start (or already past)
        if minutesUntilStart <= 15 {
            isLanyardUrgent = true
            showLanyardUrgentAlert = true
        }
    }

    // MARK: - Reminder Check

    /// Check if the volunteer has unconfirmed shifts for any session they're assigned to.
    /// Shows a blocking modal for the first unconfirmed shift found.
    private func checkForPendingReminders(sessionIds: Set<String>) async {
        for sessionId in sessionIds {
            do {
                let shifts = try await AttendantService.shared.fetchShifts(sessionId: sessionId)
                for shift in shifts {
                    if !reminderVM.hasConfirmed(shiftId: shift.id) {
                        pendingReminderShift = (id: shift.id, name: shift.name)
                        showReminderModal = true
                        return
                    }
                }
            } catch {
                print("[AttendantDept] Failed to fetch shifts for session \(sessionId): \(error)")
            }
        }
    }

    // MARK: - Captain Scheduling Card

    private var captainSchedulingCard: some View {
        NavigationLink(destination: CaptainSchedulingView(
            eventId: eventId,
            departmentId: departmentId ?? "",
            departmentType: departmentType ?? "ATTENDANT"
        )) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(DepartmentColor.color(for: "ATTENDANT").opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 20))
                        .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("captain.scheduling.title".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("captain.scheduling.desc".localized)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Captain Attendance Card

    private var captainAttendanceCard: some View {
        NavigationLink(destination: CaptainAttendanceCountsView(eventId: eventId)) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(DepartmentColor.color(for: "ATTENDANT").opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("captain.attendance.title".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("captain.attendance.desc".localized)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Quick Actions Card

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                Text("Quick Actions")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Report incident
            Button {
                showReportIncident = true
                HapticManager.shared.lightTap()
            } label: {
                actionRow(icon: "exclamationmark.triangle", title: "Report Safety Incident", color: .orange)
            }
            .buttonStyle(.plain)

            // Report lost person
            Button {
                showReportLostPerson = true
                HapticManager.shared.lightTap()
            } label: {
                actionRow(icon: "person.fill.questionmark", title: "Report Lost Person", color: .red)
            }
            .buttonStyle(.plain)

            // Walk-through checklist
            Button {
                showWalkThrough = true
                HapticManager.shared.lightTap()
            } label: {
                actionRow(icon: "checklist", title: "Walk-Through Checklist", color: .blue)
            }
            .buttonStyle(.plain)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Meetings Card

    private var meetingsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                Text("Meetings")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            NavigationLink(destination: MyAttendantMeetingsView()) {
                actionRow(icon: "calendar.badge.clock", title: "My Meetings", color: DepartmentColor.color(for: "ATTENDANT"))
            }
            .buttonStyle(.plain)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Resources Card

    private var resourcesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .foregroundStyle(DepartmentColor.color(for: "ATTENDANT"))
                Text("Resources")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            // Attendant info
            Button {
                showAttendantInfo = true
                HapticManager.shared.lightTap()
            } label: {
                actionRow(icon: "info.circle", title: "Attendant Guidelines", color: DepartmentColor.color(for: "ATTENDANT"))
            }
            .buttonStyle(.plain)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Action Row Helper

    private func actionRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
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
}
