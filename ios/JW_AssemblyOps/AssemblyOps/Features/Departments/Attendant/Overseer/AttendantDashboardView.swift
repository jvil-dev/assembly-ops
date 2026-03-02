//
//  AttendantDashboardView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Attendant Dashboard View
//
// Hub for attendant department overseer features.
// Shows summary cards for incidents, alerts, attendance, meetings, and more.
// Each card navigates to its detail management view.
// Note: Shift management was moved to SlotDetailSheet (per-post shifts).
//
// Sections:
//   - Safety Incidents Card: Unresolved incident count
//   - Lost Person Alerts Card: Unresolved alert count
//   - Attendance Counts Card: View attendance breakdowns
//   - Meetings Card: Meeting count
//
// Features:
//   - Parallel data loading on appear
//   - Pull-to-refresh
//   - Staggered entrance animations
//

import SwiftUI

struct AttendantDashboardView: View {
    @StateObject private var incidentVM = SafetyIncidentViewModel()
    @StateObject private var alertVM = LostPersonViewModel()
    @StateObject private var meetingVM = AttendantMeetingViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var isInitialLoading = true
    @State private var walkThroughCompletions: [WalkThroughCompletionItem] = []
    @State private var facilityLocations: [FacilityLocationItem] = []
    @State private var showCreateFacility = false

    private var accentColor: Color {
        if let deptType = sessionState.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    var body: some View {
        Group {
            if isInitialLoading {
                LoadingView(message: "attendant.dashboard.title".localized)
                    .themedBackground(scheme: colorScheme)
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        incidentsCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                        alertsCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                        attendanceCountsCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.1)

                        meetingsCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                        walkThroughStatusCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.2)

                        facilityGuideCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.25)

                        reminderComplianceCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.30)

                        lanyardTrackingCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.35)

                        volunteersCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.45)

                        settingsCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.50)
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.l)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
                .themedBackground(scheme: colorScheme)
                .navigationTitle("attendant.dashboard.title".localized)
                .refreshable { await loadAllData() }
                .onAppear {
                    withAnimation(AppTheme.entranceAnimation) {
                        hasAppeared = true
                    }
                }
            }
        }
        .task { await loadAllData() }
    }

    // MARK: - Incidents Card

    private var incidentsCard: some View {
        NavigationLink(destination: SafetyIncidentListView()) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(incidentVM.unresolvedCount > 0 ? AppTheme.StatusColors.warning : accentColor)
                    Text("attendant.incidents.title".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                HStack {
                    if incidentVM.unresolvedCount > 0 {
                        Text("\(incidentVM.unresolvedCount) \("attendant.incidents.unresolved".localized)")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.StatusColors.warning)
                    } else {
                        Text("attendant.incidents.empty".localized)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Alerts Card

    private var alertsCard: some View {
        NavigationLink(destination: LostPersonAlertsView()) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .foregroundStyle(alertVM.unresolvedCount > 0 ? AppTheme.StatusColors.declined : accentColor)
                    Text("attendant.lostPerson.title".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                HStack {
                    if alertVM.unresolvedCount > 0 {
                        Text("\(alertVM.unresolvedCount) \("attendant.lostPerson.active".localized)")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.StatusColors.declined)
                    } else {
                        Text("attendant.lostPerson.empty".localized)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Attendance Counts Card

    private var attendanceCountsCard: some View {
        NavigationLink(destination: AttendanceCountBreakdownView()) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "number.square")
                        .foregroundStyle(accentColor)
                    Text("attendant.attendance.title".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                HStack {
                    Text("attendant.attendance.viewCounts".localized)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Meetings Card

    private var meetingsCard: some View {
        NavigationLink(destination: AttendantMeetingsView()) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "person.3.sequence")
                        .foregroundStyle(accentColor)
                    Text("attendant.meetings.title".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                }

                HStack {
                    Text("\(meetingVM.meetings.count) \("attendant.meetings.title".localized.lowercased())")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Walk-Through Status Card

    private var walkThroughStatusCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "checklist")
                    .foregroundStyle(accentColor)
                Text("attendant.walkthrough.status.title".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if walkThroughCompletions.isEmpty {
                Text("attendant.walkthrough.status.none".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.primary)
            } else {
                ForEach(walkThroughCompletions) { completion in
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.StatusColors.accepted)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.volunteerName ?? "attendant.walkthrough.status.unknown".localized)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.primary)
                            Text("\(completion.sessionName) • \(completion.completedAt, style: .relative)")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                        Spacer()
                        Text("\(completion.itemCount) \("attendant.walkthrough.status.items".localized)")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Facility Guide Card

    private var facilityGuideCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "building.2")
                    .foregroundStyle(accentColor)
                Text("attendant.facility.title".localized.uppercased())
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                Spacer()
                Button {
                    showCreateFacility = true
                    HapticManager.shared.lightTap()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(accentColor)
                }
            }

            if facilityLocations.isEmpty {
                Text("attendant.facility.empty".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                ForEach(facilityLocations) { facility in
                    HStack(spacing: AppTheme.Spacing.s) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(accentColor)
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
                        Spacer()
                        Button {
                            Task {
                                try? await AttendantService.shared.deleteFacilityLocation(id: facility.id)
                                facilityLocations.removeAll { $0.id == facility.id }
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(AppTheme.StatusColors.declined)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
        .sheet(isPresented: $showCreateFacility) {
            CreateFacilityLocationSheet { newFacility in
                facilityLocations.append(newFacility)
            }
        }
    }

    // MARK: - Reminder Compliance Card

    private var reminderComplianceCard: some View {
        NavigationLink(destination: ReminderComplianceView()) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 20))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("attendant.dashboard.reminders".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("attendant.dashboard.remindersDesc".localized)
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

    // MARK: - Lanyard Tracking Card

    private var lanyardTrackingCard: some View {
        NavigationLink(destination: LanyardGridView()) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "lanyard")
                        .font(.system(size: 20))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("attendant.dashboard.lanyard".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("attendant.dashboard.lanyardDesc".localized)
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

    // MARK: - Volunteers Card

    private var volunteersCard: some View {
        NavigationLink(destination: VolunteerListView()) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.3")
                        .font(.system(size: 20))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("attendant.dashboard.volunteers".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("attendant.dashboard.volunteersDesc".localized)
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

    // MARK: - Settings Card

    private var settingsCard: some View {
        NavigationLink(destination: DepartmentSettingsView(departmentId: sessionState.selectedDepartment?.id ?? "")) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("attendant.dashboard.settings".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("attendant.dashboard.settingsDesc".localized)
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

    // MARK: - Data Loading

    private func loadAllData() async {
        guard let eventId = sessionState.selectedEvent?.id else {
            isInitialLoading = false
            return
        }
        async let i: () = incidentVM.loadIncidents(eventId: eventId)
        async let a: () = alertVM.loadAlerts(eventId: eventId)
        async let m: () = meetingVM.loadMeetings(eventId: eventId)
        _ = await (i, a, m)

        // Load walk-through completions and facility locations
        async let w = AttendantService.shared.fetchWalkThroughCompletions(eventId: eventId, sessionId: nil)
        async let f = AttendantService.shared.fetchFacilityLocations(eventId: eventId)
        walkThroughCompletions = (try? await w) ?? []
        facilityLocations = (try? await f) ?? []

        isInitialLoading = false
    }
}

#Preview {
    NavigationStack {
        AttendantDashboardView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        AttendantDashboardView()
    }
    .preferredColorScheme(.dark)
}
