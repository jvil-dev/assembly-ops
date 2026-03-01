//
//  AudioVolunteerDeptView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - AV Volunteer Department View
//
// Hub for AV volunteers. Shows quick actions, active equipment checkouts,
// and safety briefings attended. Similar to AttendantVolunteerDeptView.
//
// Used by: DepartmentTabRouter (for AUDIO volunteers)

import SwiftUI

struct AudioVolunteerDeptView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AudioVolunteerViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var showReportDamage = false
    @State private var showCrewInfo = false
    @State private var showError = false

    private var accentColor: Color {
        if let deptType = EventSessionState.shared.selectedDepartment?.departmentType {
            return DepartmentColor.color(for: deptType)
        }
        return AppTheme.themeColor
    }

    private var departmentName: String {
        EventSessionState.shared.selectedDepartment?.departmentType ?? "Audio"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Quick Actions
                quickActionsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                // My Equipment
                myEquipmentCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                // My Briefings
                myBriefingsCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)

                // Resources
                resourcesCard
                    .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)
            }
            .screenPadding()
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .themedBackground(scheme: colorScheme)
        .navigationTitle(departmentName)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showReportDamage) {
            ReportDamageView(equipment: viewModel.equipment)
        }
        .sheet(isPresented: $showCrewInfo) {
            AudioCrewInfoView()
        }
        .onChange(of: viewModel.error) { _, error in
            showError = error != nil
        }
        .alert("common.error".localized, isPresented: $showError) {
            Button("common.ok".localized) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .onAppear {
            withAnimation(AppTheme.entranceAnimation) {
                hasAppeared = true
            }
        }
        .task {
            if let eventId = appState.currentEventId {
                await viewModel.loadVolunteerData(eventId: eventId)
            }
        }
    }

    // MARK: - Quick Actions Card

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(accentColor)
                Text("av.volunteer.quickActions".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Button {
                showReportDamage = true
                HapticManager.shared.lightTap()
            } label: {
                actionRow(icon: "exclamationmark.triangle", title: "av.volunteer.reportDamage".localized, color: .orange)
            }
            .buttonStyle(.plain)
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - My Equipment Card

    private var myEquipmentCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "shippingbox")
                    .foregroundStyle(accentColor)
                Text("av.volunteer.myEquipment".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if viewModel.activeCheckouts.isEmpty {
                Text("av.volunteer.noCheckouts".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                ForEach(viewModel.activeCheckouts) { checkout in
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(checkout.equipmentName ?? "")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.primary)
                            Text(checkout.checkedOutAt.formatted(date: .abbreviated, time: .shortened))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                        Spacer()
                        if let cat = checkout.equipmentCategory {
                            Image(systemName: cat.icon)
                                .foregroundStyle(accentColor)
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - My Briefings Card

    private var myBriefingsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "person.3.sequence")
                    .foregroundStyle(accentColor)
                Text("av.volunteer.myBriefings".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            if viewModel.myBriefings.isEmpty {
                Text("av.volunteer.noBriefings".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            } else {
                ForEach(viewModel.myBriefings) { briefing in
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(briefing.topic)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(.primary)
                            Text(briefing.conductedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                        }
                        Spacer()
                        Text(briefing.conductedByName)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
            }
        }
        .cardPadding()
        .themedCard(scheme: colorScheme)
    }

    // MARK: - Resources Card

    private var resourcesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "book.fill")
                    .foregroundStyle(accentColor)
                Text("av.volunteer.resources".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
            }

            Button {
                showCrewInfo = true
                HapticManager.shared.lightTap()
            } label: {
                actionRow(icon: "info.circle", title: "audio.volunteer.crewInfo".localized, color: accentColor)
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

#Preview {
    AudioVolunteerDeptView()
        .environmentObject(AppState.shared)
}

#Preview("Dark Mode") {
    AudioVolunteerDeptView()
        .environmentObject(AppState.shared)
        .preferredColorScheme(.dark)
}
