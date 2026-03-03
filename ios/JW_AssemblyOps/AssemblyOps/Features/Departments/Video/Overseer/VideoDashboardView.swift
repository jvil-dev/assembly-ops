//
//  VideoDashboardView.swift
//  AssemblyOps
//
//  Created by Jorge Villeda on 2/27/26.
//

// MARK: - Video Dashboard View
//
// Hub for Video department overseers (CO-160 Ch. 4).
// Cards: Equipment, Damage Reports, Safety & Hazards, Walk-Throughs, Volunteers, Settings.
//
// Used by: DepartmentTabRouter (for VIDEO department)

import SwiftUI

struct VideoDashboardView: View {
    @StateObject private var dashboardVM = VideoDashboardViewModel()
    @ObservedObject private var sessionState = EventSessionState.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    @State private var isInitialLoading = true

    private let accentColor = DepartmentColor.color(for: "VIDEO")

    var body: some View {
        Group {
            if isInitialLoading {
                LoadingView(message: "video.dashboard.title".localized)
                    .themedBackground(scheme: colorScheme)
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        equipmentCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0)

                        damageCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.05)

                        safetyCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.10)

                        walkThroughCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.15)

                        volunteersCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.20)

                        settingsCard
                            .entranceAnimation(hasAppeared: hasAppeared, delay: 0.25)
                    }
                    .screenPadding()
                    .padding(.top, AppTheme.Spacing.l)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
                .themedBackground(scheme: colorScheme)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    await loadData()
                }
                .onAppear {
                    withAnimation(AppTheme.entranceAnimation) {
                        hasAppeared = true
                    }
                }
            }
        }
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        guard let eventId = sessionState.selectedEvent?.id else {
            isInitialLoading = false
            return
        }
        await dashboardVM.loadDashboard(eventId: eventId)
        isInitialLoading = false
    }

    // MARK: - Equipment Card

    private var equipmentCard: some View {
        NavigationLink(destination: VideoEquipmentListView()) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "video.badge.checkmark")
                        .foregroundStyle(accentColor)
                    Text("av.dashboard.equipment".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                if let summary = dashboardVM.equipmentSummary {
                    HStack(spacing: AppTheme.Spacing.s) {
                        statPill(value: summary.totalItems, label: "av.dashboard.total".localized, color: accentColor)
                        statPill(value: summary.checkedOutCount, label: "av.dashboard.checkedOut".localized, color: .orange)
                        statPill(value: summary.needsRepairCount, label: "av.dashboard.needsRepair".localized, color: AppTheme.StatusColors.warning)
                    }
                } else {
                    Text("av.dashboard.noEquipment".localized)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Damage Card

    private var damageCard: some View {
        NavigationLink(destination: VideoDamageReportsView()) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(dashboardVM.unresolvedDamageCount > 0 ? AppTheme.StatusColors.warning : accentColor)
                    Text("av.dashboard.damageReports".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Spacer()
                    if dashboardVM.unresolvedDamageCount > 0 {
                        Text("\(dashboardVM.unresolvedDamageCount)")
                            .font(AppTheme.Typography.captionSmall).fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.StatusColors.warning, in: Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                if dashboardVM.unresolvedDamageCount > 0 {
                    Text(String(format: "av.dashboard.unresolvedCount".localized, dashboardVM.unresolvedDamageCount))
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.primary)
                } else {
                    Text("av.dashboard.noDamage".localized)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Safety Card

    private var safetyCard: some View {
        NavigationLink(destination: VideoHazardAssessmentView()) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image(systemName: "shield.checkered")
                        .foregroundStyle(accentColor)
                    Text("av.dashboard.safety".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: AppTheme.Spacing.s) {
                    statPill(value: dashboardVM.hazardAssessments.count, label: "av.dashboard.hazards".localized, color: .orange)
                    statPill(value: dashboardVM.safetyBriefings.count, label: "av.dashboard.briefings".localized, color: .green)
                }
            }
            .cardPadding()
            .themedCard(scheme: colorScheme)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Walk-Through Card

    private var walkThroughCard: some View {
        NavigationLink(destination: VideoWalkThroughChecklistView(isOverseer: true)) {
            HStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "checklist")
                        .font(.system(size: 20))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("av.dashboard.walkThroughs".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("av.dashboard.walkThroughsDesc".localized)
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
                    Text("av.dashboard.volunteers".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("av.dashboard.volunteersDesc".localized)
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
                    Text("av.dashboard.settings".localized.uppercased())
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                    Text("av.dashboard.settingsDesc".localized)
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

    // MARK: - Helpers

    private func statPill(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("\(value)")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(AppTheme.Typography.captionSmall)
                .foregroundStyle(AppTheme.textTertiary(for: colorScheme))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.m)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }
}

#Preview {
    NavigationStack {
        VideoDashboardView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        VideoDashboardView()
    }
    .preferredColorScheme(.dark)
}
