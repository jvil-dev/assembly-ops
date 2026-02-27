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
//   - Attendant (Volunteer) → Attendant volunteer features
//   - All other depts → GenericDepartmentView (placeholder)
//
// The overseer's department view includes volunteer management, settings,
// check-in stats, join requests, and access code display.
// The volunteer's department view shows department-specific features
// (e.g. report incident for attendant dept).
//

import SwiftUI

struct DepartmentTabRouter: View {
    let membership: EventMembershipItem

    @EnvironmentObject private var appState: AppState
    @ObservedObject private var sessionState = EventSessionState.shared

    private var isOverseer: Bool {
        membership.membershipType == .overseer
    }

    private var departmentType: String? {
        membership.departmentType ?? sessionState.selectedDepartment?.departmentType
    }

    var body: some View {
        Group {
            if let deptType = departmentType {
                switch deptType.uppercased() {
                case "ATTENDANT":
                    if isOverseer {
                        AttendantDashboardView()
                    } else {
                        attendantVolunteerView
                    }
                default:
                    GenericDepartmentView(membership: membership)
                }
            } else {
                noDepartmentView
            }
        }
    }

    // MARK: - Attendant Volunteer View

    /// Wraps existing attendant volunteer features into a scrollable department tab.
    private var attendantVolunteerView: some View {
        AttendantVolunteerDeptView()
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

// MARK: - Attendant Volunteer Department View

/// Container view surfacing all attendant volunteer features as the department tab content.
/// Replaces the sheet-based presentation from the old HomeView.
struct AttendantVolunteerDeptView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var attendantVM = AttendantVolunteerViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var sessions: [VolunteerSessionItem] = []
    @State private var showReportIncident = false
    @State private var showReportLostPerson = false
    @State private var showAttendantInfo = false
    @State private var showWalkThrough = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Quick Actions
                    quickActionsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                    // Meetings
                    meetingsCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                    // Info & Protocol
                    resourcesCard
                        .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)
                }
                .screenPadding()
                .padding(.top, AppTheme.Spacing.l)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .themedBackground(scheme: colorScheme)
            .navigationTitle("Attendant")
            .navigationBarTitleDisplayMode(.large)
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
            .onAppear {
                withAnimation(AppTheme.entranceAnimation) {
                    hasAppeared = true
                }
            }
            .task {
                if let eventId = appState.currentEventId {
                    await attendantVM.loadMyMeetings(eventId: eventId)
                    do {
                        sessions = try await AttendanceService.shared.fetchVolunteerSessions(eventId: eventId)
                    } catch {
                        print("[AttendantDept] Failed to load sessions: \(error)")
                    }
                }
            }
        }
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
