//
//  AttendantDashboardView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/16/26.
//

// MARK: - Attendant Dashboard View
//
// Hub for attendant department overseer features.
// Shows summary cards for incidents, alerts, attendance, and meetings.
// Each card navigates to its detail management view.
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
    @ObservedObject private var sessionState = OverseerSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var isInitialLoading = true

    var body: some View {
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
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle("attendant.dashboard.title".localized)
        .refreshable { await loadAllData() }
        .task { await loadAllData() }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        }
    }

    // MARK: - Incidents Card

    private var incidentsCard: some View {
        NavigationLink(destination: SafetyIncidentListView()) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(incidentVM.unresolvedCount > 0 ? AppTheme.StatusColors.warning : AppTheme.themeColor)
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
                        .foregroundStyle(alertVM.unresolvedCount > 0 ? AppTheme.StatusColors.declined : AppTheme.themeColor)
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
                        .foregroundStyle(AppTheme.themeColor)
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
                        .foregroundStyle(AppTheme.themeColor)
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
